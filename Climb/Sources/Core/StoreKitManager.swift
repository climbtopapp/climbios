import Foundation
import StoreKit
import SwiftUI

/// Manages In-App Purchases using StoreKit 2
@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    static let gradeProductID = "grade"
    static let gradeAppleID = "6792864994"

    static let steps100ProductID = "100"
    static let steps100AppleID = "6801378143"

    @Published private(set) var isGradePurchased: Bool = false
    @Published private(set) var gradeProduct: Product? = nil
    @Published private(set) var steps100Product: Product? = nil
    @Published var isLoading: Bool = false
    @Published var isPurchasingSteps: Bool = false
    @Published var errorMessage: String? = nil

    private var updateListenerTask: Task<Void, Error>? = nil

    private init() {
        // Start listening for asynchronous transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// Load product information from App Store Connect or StoreKit configuration
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.gradeProductID, Self.steps100ProductID])
            print("StoreKit: Fetched \(products.count) products from App Store: \(products.map { $0.id })")
            for product in products {
                if product.id == Self.gradeProductID {
                    self.gradeProduct = product
                } else if product.id == Self.steps100ProductID {
                    self.steps100Product = product
                }
            }
        } catch {
            print("StoreKit: Failed to fetch products: \(error)")
        }
    }

    /// Check current active entitlements for the grade product
    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.gradeProductID && transaction.revocationDate == nil {
                self.isGradePurchased = true
                return
            }
        }
    }

    /// Purchase the Personal Grade in-app purchase
    func purchaseGrade() async -> Bool {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        var targetProduct = gradeProduct
        if targetProduct == nil {
            await loadProducts()
            targetProduct = gradeProduct
        }

        if targetProduct == nil {
            // Direct query fallback
            do {
                let prods = try await Product.products(for: [Self.gradeProductID])
                targetProduct = prods.first
                self.gradeProduct = targetProduct
            } catch {
                print("StoreKit: Direct query for grade failed: \(error)")
            }
        }

        guard let product = targetProduct else {
            #if DEBUG
            print("StoreKit: Product '\(Self.gradeProductID)' not returned from App Store (likely in 'Prepare for Submission'). Development simulation unlock enabled.")
            self.isGradePurchased = true
            return true
            #else
            errorMessage = "Could not load Personal Grade from App Store. Please try again later."
            return false
            #endif
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                self.isGradePurchased = true
                return true

            case .userCancelled:
                return false

            case .pending:
                errorMessage = "Purchase is pending approval."
                return false

            @unknown default:
                return false
            }
        } catch {
            print("StoreKit: Purchase failed: \(error)")
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Purchase 100 Steps consumable in-app purchase
    func purchase100Steps() async -> Bool {
        isPurchasingSteps = true
        errorMessage = nil

        defer { isPurchasingSteps = false }

        var targetProduct = steps100Product
        if targetProduct == nil {
            await loadProducts()
            targetProduct = steps100Product
        }

        if targetProduct == nil {
            // Direct query fallback
            do {
                let prods = try await Product.products(for: [Self.steps100ProductID])
                targetProduct = prods.first
                self.steps100Product = targetProduct
            } catch {
                print("StoreKit: Direct query for 100 Steps failed: \(error)")
            }
        }

        guard let product = targetProduct else {
            #if DEBUG
            print("StoreKit: Product '\(Self.steps100ProductID)' not returned from App Store (likely in 'Prepare for Submission'). Development simulation purchase enabled.")
            return true
            #else
            errorMessage = "Could not load 100 Steps from App Store. Please try again later."
            return false
            #endif
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                return true

            case .userCancelled:
                return false

            case .pending:
                errorMessage = "Purchase is pending approval."
                return false

            @unknown default:
                return false
            }
        } catch {
            print("StoreKit: 100 Steps purchase failed: \(error)")
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            print("StoreKit: Restore failed: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    /// Manually unlock for testing/demo
    func setUnlockedForDemo() {
        self.isGradePurchased = true
    }

    /// Verify transaction signature
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    /// Listen for background transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    if transaction.productID == Self.gradeProductID && transaction.revocationDate == nil {
                        await MainActor.run {
                            self.isGradePurchased = true
                        }
                    }
                    await transaction.finish()
                } catch {
                    print("StoreKit: Unverified transaction update: \(error)")
                }
            }
        }
    }
}
