import Foundation
import CoreData

class CreditHistoryManager {
    static let shared = CreditHistoryManager()
    
    private init() {}
    
    // Credit score ranges from 0 to 1000
    func calculateCreditScore(for user: CDUser) -> Int {
        print("Calculating score for user: \(user.firstName ?? "No name")")
        print("Balance: \(user.balance)")
        print("Loans count: \(user.loans?.count ?? 0)")
        print("Mortgages count: \(user.mortgages?.count ?? 0)")
        print("Transactions count: \(user.transactions?.count ?? 0)")
        
        let transactions = user.transactions?.allObjects as? [CDTransaction] ?? []
        let loans = user.loans?.allObjects as? [Loan] ?? []
        let mortgages = user.mortgages?.allObjects as? [Mortgage] ?? []
        
        // Start with a lower base score
        var score = 300
        
        // Account age factor
        if let issueDate = user.issueDate {
            let accountAgeInDays = Calendar.current.dateComponents([.day], from: issueDate, to: Date()).day ?? 0
            score += min(accountAgeInDays / 7, 100) // Up to 100 points for account age (1 point per week)
        }
        
        // Transaction history factor
        let transactionCount = transactions.count
        score += min(transactionCount * 5, 100) // Up to 100 points for transaction history
        
        // Balance factor
        let balance = user.balance
        if balance >= 100_000 {
            score += 100
        } else if balance >= 50_000 {
            score += 50
        } else if balance >= 10_000 {
            score += 25
        }
        
        // Calculate score based on loan history
        for loan in loans {
            if loan.isActive {
                // Active loans slightly decrease score
                score -= 20
                
                // Check if payments are being made on time
                if let nextPaymentDate = loan.nextPaymentDate,
                   nextPaymentDate < Date() {
                    score -= 50 // Penalty for overdue payment
                }
            } else {
                // Successfully completed loans increase score significantly
                score += 75
            }
            
            // Penalize for late payments
            let latePayments = loan.latePayments
            if latePayments > 0 {
                score -= Int(latePayments * 30)
            }
        }
        
        // Calculate score based on mortgage history
        for mortgage in mortgages {
            if mortgage.isActive {
                // Having an active mortgage slightly improves score if payments are on time
                score += 30
                
                // Check mortgage amount vs balance ratio
                let mortgageToBalanceRatio = mortgage.amount / max(user.balance, 1) // avoid division by zero
                if mortgageToBalanceRatio <= 3 {
                    score += 20 // Bonus for reasonable mortgage amount
                }
            } else {
                // Successfully completed mortgages significantly improve score
                score += 150
            }
            
            // Penalize for late payments
            let latePayments = mortgage.latePayments
            if latePayments > 0 {
                score -= Int(latePayments * 50)
            }
        }
        
        // Additional factors
        
        // Transaction frequency in last month
        let recentTransactions = transactions.filter { transaction in
            if let date = transaction.date {
                return date > Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            }
            return false
        }
        if recentTransactions.count >= 5 {
            score += 25 // Bonus for active account usage
        }
        
        // Ensure score stays within bounds
        score = max(0, min(1000, score))
        print("Final credit score for user \(user.firstName ?? "No name"): \(score)")
        return score
    }
    
    func canTakeMortgage(for user: CDUser) -> Bool {
        // Check if user already has an active mortgage
        let mortgages = user.mortgages?.allObjects as? [Mortgage] ?? []
        let hasActiveMortgage = mortgages.contains { $0.isActive }
        
        if hasActiveMortgage {
            return false
        }
        
        // Check credit score
        let creditScore = calculateCreditScore(for: user)
        return creditScore >= 600
    }
    
    func getMaxMortgageAmount(for user: CDUser) -> Double {
        let creditScore = calculateCreditScore(for: user)
        
        // Base multiplier based on credit score
        let baseMultiplier: Double
        switch creditScore {
        case 900...1000:
            baseMultiplier = 5.0 // Can borrow up to 5x annual income
        case 800...899:
            baseMultiplier = 4.0
        case 700...799:
            baseMultiplier = 3.0
        case 600...699:
            baseMultiplier = 2.0
        default:
            baseMultiplier = 0.0 // Not eligible for mortgage
        }
        
        // Calculate based on user's balance as proxy for income
        let maxAmount = user.balance * baseMultiplier
        
        // Cap at reasonable amount
        return min(maxAmount, 10_000_000)
    }
    
    func canTakeCredit(for user: CDUser) -> Bool {
        let creditScore = calculateCreditScore(for: user)
        return creditScore >= 400
    }
    
    func getMaxCreditAmount(for user: CDUser) -> Double {
        let creditScore = calculateCreditScore(for: user)
        
        // Base amount based on credit score
        let baseAmount: Double
        switch creditScore {
        case 800...1000:
            baseAmount = 1_000_000
        case 600...799:
            baseAmount = 500_000
        case 400...599:
            baseAmount = 100_000
        default:
            baseAmount = 0
        }
        
        // Adjust based on user's balance
        let balanceMultiplier = min(user.balance / 10_000, 2.0)
        return baseAmount * balanceMultiplier
    }
    
    func getCreditInterestRate(for user: CDUser) -> Double {
        let creditScore = calculateCreditScore(for: user)
        
        // Base rate based on credit score
        switch creditScore {
        case 900...1000:
            return 8.0
        case 800...899:
            return 10.0
        case 700...799:
            return 12.0
        case 600...699:
            return 14.0
        case 400...599:
            return 16.0
        default:
            return 20.0
        }
    }
}
