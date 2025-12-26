import Foundation
import RevenueCat
import SwiftUI

/// Paywall trigger context - determines messaging shown to user
enum PaywallTrigger: Equatable {
    case createPrism      // 4th creation attempt
    case syncPrisms       // tapping sync when not Pro
    case sharePrism       // export/share action
    case generic          // general upgrade prompt
}

/// Single source of truth for entitlements.
/// Wraps RevenueCat and exposes reactive state for UI.
@MainActor
@Observable
final class EntitlementStore {

    // MARK: - Constants

    static let apiKey = "test_QArUZtzrmALZopkBqorBIbQIhKi"
    static let entitlementId = "prism_pro"
    static let freePrismLimit = 3

    // MARK: - Published State

    private(set) var customerInfo: CustomerInfo?
    private(set) var offerings: Offerings?
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Computed Properties

    /// User has active Prism Pro entitlement
    var hasPro: Bool {
        customerInfo?.entitlements[Self.entitlementId]?.isActive == true
    }

    /// Check if user can create another prism given current count
    func canCreatePrism(userCreatedCount: Int) -> Bool {
        hasPro || userCreatedCount < Self.freePrismLimit
    }

    /// Check if user can sync (requires Pro)
    var canSync: Bool { hasPro }

    /// Current offering for paywall
    var currentOffering: Offering? { offerings?.current }

    /// Weekly package from current offering
    var weeklyPackage: Package? { currentOffering?.weekly }

    /// Monthly package from current offering
    var monthlyPackage: Package? { currentOffering?.monthly }

    /// Annual package from current offering
    var annualPackage: Package? { currentOffering?.annual }

    // MARK: - Init

    init() {
        // Listen to customer info updates automatically
        Task {
            for await info in Purchases.shared.customerInfoStream {
                self.customerInfo = info
            }
        }
    }

    // MARK: - Configuration

    /// Configure RevenueCat SDK - call once at app launch
    static func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif

        Purchases.configure(
            with: .builder(withAPIKey: apiKey)
                .with(storeKitVersion: .storeKit2)
                .build()
        )
    }

    // MARK: - Fetch

    /// Fetch offerings and customer info
    func fetchOfferings() async {
        isLoading = true
        error = nil

        do {
            async let fetchedOfferings = Purchases.shared.offerings()
            async let fetchedInfo = Purchases.shared.customerInfo()

            let (offerings, info) = try await (fetchedOfferings, fetchedInfo)

            self.offerings = offerings
            self.customerInfo = info
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Purchase

    /// Purchase a package
    @discardableResult
    func purchase(_ package: Package) async throws -> CustomerInfo {
        isLoading = true
        error = nil

        do {
            let result = try await Purchases.shared.purchase(package: package)
            self.customerInfo = result.customerInfo
            isLoading = false
            return result.customerInfo
        } catch {
            isLoading = false

            // Don't treat cancellation as error
            if let rcError = error as? RevenueCat.ErrorCode,
               rcError == .purchaseCancelledError {
                throw error
            }

            self.error = error
            throw error
        }
    }

    // MARK: - Restore

    /// Restore previous purchases
    @discardableResult
    func restorePurchases() async throws -> CustomerInfo {
        isLoading = true
        error = nil

        do {
            let info = try await Purchases.shared.restorePurchases()
            self.customerInfo = info
            isLoading = false
            return info
        } catch {
            isLoading = false
            self.error = error
            throw error
        }
    }

    // MARK: - User Identification

    /// Log in a user to RevenueCat (after auth)
    func logIn(userId: String) async throws {
        let (info, _) = try await Purchases.shared.logIn(userId)
        self.customerInfo = info
    }

    /// Log out user from RevenueCat
    func logOut() async throws {
        let info = try await Purchases.shared.logOut()
        self.customerInfo = info
    }
}
