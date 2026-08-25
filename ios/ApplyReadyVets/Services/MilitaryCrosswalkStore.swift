import Foundation

actor MilitaryCrosswalkStore {
    static let shared = MilitaryCrosswalkStore()

    private var cachedDataset: MilitaryCrosswalkDataset?

    func search(
        branch: MilitaryBranch?,
        query: String
    ) throws -> (metadata: MilitaryCrosswalkMetadata, matches: [MilitaryOccupationMapping]) {
        let dataset = try load()
        return (
            dataset.metadata,
            MilitaryOccupationSearch.search(
                dataset.records,
                branch: branch,
                query: query
            )
        )
    }

    private func load() throws -> MilitaryCrosswalkDataset {
        if let cachedDataset { return cachedDataset }
        guard let url = Bundle.main.url(
            forResource: "MilitaryOccupationCrosswalk",
            withExtension: "json"
        ) else {
            throw CrosswalkError.missingResource
        }
        let dataset = try JSONDecoder().decode(
            MilitaryCrosswalkDataset.self,
            from: Data(contentsOf: url)
        )
        guard dataset.metadata.includedRecords == dataset.records.count else {
            throw CrosswalkError.recordCountMismatch
        }
        cachedDataset = dataset
        return dataset
    }

    private enum CrosswalkError: LocalizedError {
        case missingResource
        case recordCountMismatch

        var errorDescription: String? {
            switch self {
            case .missingResource:
                "The official military occupation crosswalk is missing from this build."
            case .recordCountMismatch:
                "The military occupation crosswalk did not pass its integrity check."
            }
        }
    }
}
