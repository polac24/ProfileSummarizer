import ProfileReader

public protocol BazelActionVisitor {
    func visit(_ action: BazelAction)
}

public struct BazelActionFilterMode: OptionSet, BazelActionFilter {
    public let rawValue: Int

    static let empty = BazelActionFilterMode([])
    static let localCache = BazelActionFilterMode(rawValue: 1 << 1)
    static let remoteCache = BazelActionFilterMode(rawValue: 1 << 2)
    static let cacheMiss = BazelActionFilterMode(rawValue: 1 << 3)
    static let nonCacheable = BazelActionFilterMode(rawValue: 1 << 4)
    static let all = BazelActionFilterMode(rawValue: Int.min)

    public func filter(_ action: BazelAction) -> Bool {
        let correspondingOption: Self
        switch action.cacheResult {
        case .miss: correspondingOption = .cacheMiss
        case .local: correspondingOption = .localCache
        case .remote: correspondingOption = .remoteCache
        case .noncacheable: correspondingOption = .nonCacheable
        }
        return correspondingOption.rawValue != 0
    }

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public protocol BazelActionFilter {
    func filter(_ action: BazelAction) -> Bool
}
public enum BazelActionFilterConfiguration: BazelActionFilter {
    case mode(BazelActionFilterMode)
    case block((BazelAction) -> Bool)

    public func filter(_ action: BazelAction) -> Bool {
        switch self {
        case .block(let block): return block(action)
        case .mode(let mode): return mode.filter(action)
        }
    }
}

public struct BazelActionFilterComposition: BazelActionFilter {
    private let filters: [BazelActionFilter]

    public init(filters: [BazelActionFilter]) {
        self.filters = filters
    }
    public func filter(_ action: ProfileReader.BazelAction) -> Bool {
        filters.first { filter in
            filter.filter(action)
        } != nil
    }
}

