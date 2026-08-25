import StoreKit
import StoreKitTest
import XCTest
@testable import ApplyReadyVets

@MainActor
final class StoreKitEntitlementTests: XCTestCase {
    func testProtectedLaunchWorkWaitsForEntitlementAndLocalErase() {
        XCTAssertFalse(
            ProtectedLaunchWorkGate.allowsHandling(
                entitlementResolved: false,
                localErasePending: false
            )
        )
        XCTAssertFalse(
            ProtectedLaunchWorkGate.allowsHandling(
                entitlementResolved: true,
                localErasePending: true
            )
        )
        XCTAssertTrue(
            ProtectedLaunchWorkGate.allowsHandling(
                entitlementResolved: true,
                localErasePending: false
            )
        )
    }

    func testCatalogContainsOnlyFiveNinetyNineLifetimeProduct() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }

        let products = try await Product.products(
            for: [
                EntitlementManager.completeProductID,
                "com.jonathanhogue.applyreadyvets.unknown"
            ]
        )
        let product = try XCTUnwrap(
            products.first { $0.id == EntitlementManager.completeProductID }
        )

        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertEqual(product.price, try XCTUnwrap(Decimal(string: "5.99")))
        XCTAssertFalse(product.isFamilyShareable)

        let manager = EntitlementManager(storefrontEnabledOverride: true)
        XCTAssertFalse(manager.hasResolvedInitialEntitlement)
        XCTAssertFalse(manager.canRestorePurchases)
        await manager.start()
        XCTAssertEqual(
            manager.completeProduct?.id,
            EntitlementManager.completeProductID
        )
        XCTAssertFalse(manager.hasComplete)
        XCTAssertTrue(manager.hasResolvedInitialEntitlement)
        XCTAssertTrue(manager.canRestorePurchases)
    }

    func testInitialEntitlementResolvesWithoutAStorefrontCatalog() async {
        let manager = EntitlementManager(storefrontEnabledOverride: false)

        XCTAssertFalse(manager.hasResolvedInitialEntitlement)
        await manager.start()

        XCTAssertTrue(manager.hasResolvedInitialEntitlement)
        XCTAssertFalse(manager.hasComplete)
        XCTAssertNil(manager.completeProduct)
        XCTAssertFalse(manager.canRestorePurchases)
    }

    func testFailedCatalogCanBeRetriedWithoutRepeatingEntitlementStartup() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        try await session.setSimulatedError(
            .generic(.networkError(URLError(.notConnectedToInternet))),
            forAPI: .loadProducts
        )
        let manager = EntitlementManager(storefrontEnabledOverride: true)

        await manager.start()

        XCTAssertTrue(manager.hasResolvedInitialEntitlement)
        XCTAssertNil(manager.completeProduct)
        XCTAssertEqual(
            manager.message,
            "Apple purchase options are unavailable right now."
        )
        XCTAssertTrue(manager.canRestorePurchases)

        try await session.setSimulatedError(nil, forAPI: .loadProducts)
        await manager.reloadProducts()

        XCTAssertEqual(
            manager.completeProduct?.id,
            EntitlementManager.completeProductID
        )
        XCTAssertEqual(manager.message, "")
        XCTAssertFalse(manager.isLoading)
        XCTAssertTrue(manager.canRestorePurchases)
    }

    func testSuccessfulPurchaseUnlocksCompleteAndCreatesPurchasedTransaction() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        let manager = try await startedManager()

        await manager.purchaseComplete()

        XCTAssertTrue(manager.hasComplete)
        XCTAssertEqual(manager.message, "ApplyReady Vets Complete is now active.")
        XCTAssertFalse(manager.isLoading)

        let transaction = try XCTUnwrap(session.allTransactions().first)
        XCTAssertEqual(transaction.productIdentifier, EntitlementManager.completeProductID)
        XCTAssertEqual(transaction.state, .purchased)
        XCTAssertFalse(transaction.pendingAskToBuyConfirmation)
        XCTAssertNil(transaction.cancelDate)
        XCTAssertNil(transaction.expirationDate)
    }

    func testUserCancellationDoesNotUnlockOrReportAnError() {
        let manager = EntitlementManager(storefrontEnabledOverride: true)

        manager.applyPurchaseDisposition(.userCancelled)

        XCTAssertFalse(manager.hasComplete)
        XCTAssertEqual(manager.message, "No purchase was made.")
        XCTAssertFalse(manager.isLoading)
    }

    func testStoreKitPurchaseFailureDoesNotUnlockComplete() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        let manager = try await startedManager()
        try await session.setSimulatedError(
            .generic(.unknown),
            forAPI: .purchase
        )

        await manager.purchaseComplete()

        XCTAssertFalse(manager.hasComplete)
        XCTAssertEqual(manager.message, "The purchase could not be completed.")
        XCTAssertFalse(manager.isLoading)
        XCTAssertTrue(session.allTransactions().isEmpty)
    }

    func testAskToBuyStaysLockedUntilApprovedThenUnlocks() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        session.askToBuyEnabled = true
        let manager = try await startedManager()

        await manager.purchaseComplete()

        XCTAssertFalse(manager.hasComplete)
        XCTAssertEqual(manager.message, "The App Store marked this purchase as pending.")
        let pendingTransaction = try XCTUnwrap(session.allTransactions().first)
        XCTAssertTrue(pendingTransaction.pendingAskToBuyConfirmation)

        try session.approveAskToBuyTransaction(identifier: pendingTransaction.identifier)
        let becameActive = await eventually {
            await manager.refreshEntitlement()
            return manager.hasComplete
        }

        XCTAssertTrue(becameActive)
        XCTAssertEqual(manager.message, "ApplyReady Vets Complete is now active.")
    }

    func testRestoreFindsAnExistingLifetimePurchase() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        do {
            let purchasingManager = try await startedManager()
            await purchasingManager.purchaseComplete()
            XCTAssertTrue(purchasingManager.hasComplete)
        }
        let manager = try await startedManager()

        XCTAssertTrue(manager.hasComplete)
        await manager.restorePurchases()

        XCTAssertTrue(manager.hasComplete)
        XCTAssertEqual(manager.message, "ApplyReady Vets Complete was restored.")
        XCTAssertFalse(manager.isLoading)
    }

    func testRestoreWithoutPurchaseKeepsFreeAccess() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        let manager = try await startedManager()

        await manager.restorePurchases()

        XCTAssertFalse(manager.hasComplete)
        XCTAssertEqual(
            manager.message,
            "No lifetime unlock was found for this Apple Account."
        )
        XCTAssertFalse(manager.isLoading)
    }

    func testRestoreFailureKeepsAccessLockedAndExplainsRetry() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        let manager = try await startedManager()
        try await session.setSimulatedError(
            .generic(.networkError(URLError(.notConnectedToInternet))),
            forAPI: .appStoreSync
        )

        await manager.restorePurchases()

        XCTAssertFalse(manager.hasComplete)
        XCTAssertEqual(
            manager.message,
            "The App Store could not restore purchases right now."
        )
        XCTAssertFalse(manager.isLoading)
    }

    func testRefundRevokesLifetimeEntitlement() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        let manager = try await startedManager()
        await manager.purchaseComplete()
        XCTAssertTrue(manager.hasComplete)

        let purchasedTransaction = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: purchasedTransaction.identifier)
        let becameInactive = await eventually {
            await manager.refreshEntitlement()
            return !manager.hasComplete
        }

        XCTAssertTrue(becameInactive)
        XCTAssertEqual(
            manager.message,
            "Complete access is no longer active after a refund or revocation."
        )
        XCTAssertNotNil(
            session.allTransactions()
                .first { $0.identifier == purchasedTransaction.identifier }?
                .cancelDate
        )
    }

    func testUnverifiedPurchaseNeverUnlocksComplete() async throws {
        let session = try makeSession()
        defer { cleanUp(session) }
        let manager = try await startedManager()
        try await session.setSimulatedError(
            .verification(.invalidSignature),
            forAPI: .verification
        )

        await manager.purchaseComplete()

        XCTAssertFalse(manager.hasComplete)
        XCTAssertEqual(
            manager.message,
            "The App Store could not verify this purchase."
        )
        XCTAssertFalse(manager.isLoading)
    }

    func testUnknownRevokedAndExpiredTransactionsCannotGrantComplete() {
        let now = Date(timeIntervalSince1970: 2_000)

        XCTAssertFalse(
            EntitlementManager.completeEntitlementIsActive(
                productID: "com.jonathanhogue.applyreadyvets.unknown",
                revocationDate: nil,
                expirationDate: nil,
                now: now
            )
        )
        XCTAssertFalse(
            EntitlementManager.completeEntitlementIsActive(
                productID: EntitlementManager.completeProductID,
                revocationDate: now,
                expirationDate: nil,
                now: now
            )
        )
        XCTAssertFalse(
            EntitlementManager.completeEntitlementIsActive(
                productID: EntitlementManager.completeProductID,
                revocationDate: nil,
                expirationDate: now.addingTimeInterval(-1),
                now: now
            )
        )
        XCTAssertTrue(
            EntitlementManager.completeEntitlementIsActive(
                productID: EntitlementManager.completeProductID,
                revocationDate: nil,
                expirationDate: nil,
                now: now
            )
        )
        XCTAssertTrue(
            EntitlementManager.completeEntitlementIsActive(
                productID: EntitlementManager.completeProductID,
                revocationDate: nil,
                expirationDate: now.addingTimeInterval(1),
                now: now
            )
        )

        let manager = EntitlementManager(storefrontEnabledOverride: true)
        XCTAssertTrue(
            manager.applyVerifiedEntitlement(
                productID: EntitlementManager.completeProductID,
                revocationDate: nil,
                expirationDate: nil,
                now: now
            )
        )
        let activeMessage = manager.message

        XCTAssertFalse(
            manager.applyVerifiedEntitlement(
                productID: "com.jonathanhogue.applyreadyvets.unknown",
                revocationDate: nil,
                expirationDate: nil,
                now: now
            )
        )
        XCTAssertTrue(manager.hasComplete)
        XCTAssertEqual(manager.message, activeMessage)

        XCTAssertFalse(
            manager.applyUnverifiedEntitlement(
                productID: "com.jonathanhogue.applyreadyvets.unknown"
            )
        )
        XCTAssertTrue(manager.hasComplete)
        XCTAssertEqual(manager.message, activeMessage)
    }

    private func makeSession() throws -> SKTestSession {
        let configurationURL = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: "ApplyReadyVets",
                withExtension: "storekit"
            )
        )
        let session = try SKTestSession(contentsOf: configurationURL)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        return session
    }

    private func cleanUp(_ session: SKTestSession) {
        session.clearTransactions()
        session.resetToDefaultState()
    }

    private func startedManager() async throws -> EntitlementManager {
        let manager = EntitlementManager(storefrontEnabledOverride: true)
        await manager.start()
        _ = try XCTUnwrap(manager.completeProduct)
        return manager
    }

    private func eventually(
        timeout: Duration = .seconds(3),
        condition: @MainActor () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        repeat {
            if await condition() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(50))
        } while clock.now < deadline
        return await condition()
    }
}
