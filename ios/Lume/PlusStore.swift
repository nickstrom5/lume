import Foundation
import StoreKit
import Observation

enum PlusProduct: String, CaseIterable {
    case yearly = "app.lumenow.lume.plus.yearly"
    case weekly = "app.lumenow.lume.plus.weekly"
}

@MainActor
@Observable
final class PlusStore {
    var products: [Product] = []
    var purchased: Set<String> = []
    var isBusy = false
    var error: String?

    var isPlus: Bool { !purchased.isEmpty }

    var yearly: Product? { products.first { $0.id == PlusProduct.yearly.rawValue } }
    var weekly: Product? { products.first { $0.id == PlusProduct.weekly.rawValue } }

    func start() async {
        await refreshProducts()
        await refreshPurchases()
        Task { await listen() }
    }

    func refreshProducts() async {
        do {
            products = try await Product.products(for: PlusProduct.allCases.map(\.rawValue))
                .sorted { $0.price > $1.price }
        } catch {
            self.error = "Could not load plans."
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isBusy = true
        defer { isBusy = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try check(verification)
                purchased.insert(transaction.productID)
                await transaction.finish()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshPurchases()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func refreshPurchases() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let t = try? check(result) {
                ids.insert(t.productID)
            }
        }
        purchased = ids
    }

    private func listen() async {
        for await result in Transaction.updates {
            if let t = try? check(result) {
                purchased.insert(t.productID)
                await t.finish()
            }
        }
    }

    private func check(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let t): return t
        }
    }
}
