import Foundation
import StoreKit

@MainActor
protocol AccessEntitling: AnyObject {
    var hasComplete: Bool { get }
}

@MainActor
final class FreeAccessEntitlement: AccessEntitling {
    let hasComplete = false
}

@MainActor
final class EntitlementManager: ObservableObject, AccessEntitling {
    enum PurchaseDisposition {
        case pending
        case userCancelled
        case unknown
    }

    nonisolated static let completeProductID =
        "com.jonathanhogue.applyreadyvets.complete.lifetime"

    @Published private(set) var completeProduct: Product?
    @Published private(set) var hasComplete = false
    @Published private(set) var hasResolvedInitialEntitlement = false
    @Published private(set) var isLoading = false
    @Published private(set) var message = ""

    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false
    private let storefrontEnabledOverride: Bool?

    init(storefrontEnabledOverride: Bool? = nil) {
        self.storefrontEnabledOverride = storefrontEnabledOverride
    }

    var storefrontEnabled: Bool {
        if let storefrontEnabledOverride {
            return storefrontEnabledOverride
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "HOGUE_STOREFRONT_ENABLED")
        if let enabled = value as? Bool { return enabled }
        if let string = value as? String {
            return ["1", "yes", "true"].contains(string.lowercased())
        }
        return false
    }

    var canRestorePurchases: Bool {
        storefrontEnabled && hasResolvedInitialEntitlement && !isLoading
    }

    func start() async {
        if hasStarted {
            // SwiftUI may cancel and recreate a view task during launch. A
            // second caller must finish the initial check instead of returning
            // with the app permanently stuck in its protected launch screen.
            guard !hasResolvedInitialEntitlement else { return }
            await refreshEntitlement()
            hasResolvedInitialEntitlement = true
            await reloadProducts()
            return
        }
        hasStarted = true

        if ProcessInfo.processInfo.arguments.contains("-COMPLETE_UNLOCKED") {
            hasComplete = true
            hasResolvedInitialEntitlement = true
            message = "Complete access is active for UI testing."
            return
        }

        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                await self.process(result)
            }
        }
        await refreshEntitlement()
        // Routing that can create a paid workspace must wait for this state,
        // but it does not need to wait on a potentially slower catalog request.
        hasResolvedInitialEntitlement = true
        await reloadProducts()
    }

    func purchaseComplete() async {
        guard !isLoading else { return }
        guard let completeProduct else {
            message = "The lifetime unlock is unavailable right now."
            return
        }
        await purchase(completeProduct)
    }

    func restorePurchases() async {
        guard canRestorePurchases else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            message = hasComplete
                ? "ApplyReady Vets Complete was restored."
                : "No lifetime unlock was found for this Apple Account."
        } catch {
            message = "The App Store could not restore purchases right now."
        }
    }

    func reloadProducts() async {
        guard storefrontEnabled, hasResolvedInitialEntitlement, !isLoading else {
            return
        }
        isLoading = true
        defer { isLoading = false }
        completeProduct = nil
        if message == "The lifetime unlock is unavailable right now." ||
            message == "Apple purchase options are unavailable right now." {
            message = ""
        }

        do {
            let products = try await Product.products(for: [Self.completeProductID])
            guard let product = products.first(where: { $0.id == Self.completeProductID }),
                  product.type == .nonConsumable else {
                message = "The lifetime unlock is unavailable right now."
                return
            }
            completeProduct = product
        } catch {
            message = "Apple purchase options are unavailable right now."
        }
    }

    func refreshEntitlement() async {
        guard let result = await Transaction.latest(for: Self.completeProductID) else {
            hasComplete = false
            return
        }

        switch result {
        case .verified(let transaction):
            applyVerifiedEntitlement(
                productID: transaction.productID,
                revocationDate: transaction.revocationDate,
                expirationDate: transaction.expirationDate
            )
        case .unverified(let transaction, _):
            applyUnverifiedEntitlement(productID: transaction.productID)
        }
    }

    private func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch try await product.purchase() {
            case .success(let result):
                await process(result)
            case .pending:
                applyPurchaseDisposition(.pending)
            case .userCancelled:
                applyPurchaseDisposition(.userCancelled)
            @unknown default:
                applyPurchaseDisposition(.unknown)
            }
        } catch StoreKitError.userCancelled {
            applyPurchaseDisposition(.userCancelled)
        } catch {
            message = "The purchase could not be completed."
        }
    }

    private func process(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            applyVerifiedEntitlement(
                productID: transaction.productID,
                revocationDate: transaction.revocationDate,
                expirationDate: transaction.expirationDate
            )
            await transaction.finish()
        case .unverified(let transaction, _):
            applyUnverifiedEntitlement(productID: transaction.productID)
        }
    }

    @discardableResult
    func applyVerifiedEntitlement(
        productID: String,
        revocationDate: Date?,
        expirationDate: Date?,
        now: Date = Date()
    ) -> Bool {
        guard productID == Self.completeProductID else {
            return false
        }

        hasComplete = Self.completeEntitlementIsActive(
            productID: productID,
            revocationDate: revocationDate,
            expirationDate: expirationDate,
            now: now
        )
        if hasComplete {
            message = "ApplyReady Vets Complete is now active."
        } else if revocationDate != nil {
            message = "Complete access is no longer active after a refund or revocation."
        } else {
            message = "Complete access is no longer active for this purchase."
        }
        return true
    }

    @discardableResult
    func applyUnverifiedEntitlement(productID: String) -> Bool {
        guard productID == Self.completeProductID else {
            return false
        }

        hasComplete = false
        message = "The App Store could not verify this purchase."
        return true
    }

    func applyPurchaseDisposition(_ disposition: PurchaseDisposition) {
        switch disposition {
        case .pending:
            message = "The App Store marked this purchase as pending."
        case .userCancelled:
            message = "No purchase was made."
        case .unknown:
            message = "The App Store returned an unknown purchase status."
        }
    }

    nonisolated static func completeEntitlementIsActive(
        productID: String,
        revocationDate: Date?,
        expirationDate: Date?,
        now: Date
    ) -> Bool {
        guard productID == completeProductID,
              revocationDate == nil else {
            return false
        }
        return expirationDate.map { $0 > now } ?? true
    }
}
