import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "Model") // замените на имя .xcdatamodeld файла
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Ошибка загрузки хранилища Core Data: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    func saveMortgage(amount: Double, termYears: Int, rate: Double, monthly: Double, total: Double, overpay: Double) {
        let mortgage = Mortgage(context: context)
        mortgage.amount = amount
        mortgage.termYears = Int16(termYears)
        mortgage.rate = rate
        mortgage.monthlyPayment = monthly
        mortgage.totalPayment = total
        mortgage.overpayment = overpay
        mortgage.date = Date()
        
        saveContext()
    }
    
    func saveLoan(amount: Double, termMonths: Int, rate: Double, monthlyPayment: Double, totalAmount: Double) {
        let loan = Loan(context: context)
        loan.amount = amount
        loan.termMonths = Int16(termMonths)
        loan.interestRate = rate
        loan.monthlyPayment = monthlyPayment
        loan.totalAmount = totalAmount
        loan.remainingDebt = totalAmount
        loan.date = Date()
        
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) {
            loan.nextPaymentDate = nextMonth
            loan.nextPaymentAmount = monthlyPayment
        }
        
        saveContext()
    }
    
    func saveDeposit(amount: Double, termMonths: Int, interestRate: Double, totalInterest: Double) {
        let deposit = Deposit(context: context)
        deposit.amount = amount
        deposit.termMonths = Int16(termMonths)
        deposit.interestRate = interestRate
        deposit.totalInterest = totalInterest
        deposit.date = Date()
        
        saveContext()
    }
    
    // ✅ Теперь публичный
    func saveContext() {
        do {
            try context.save()
            print("Successfully saved to CoreData")
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // ✅ Добавили
    func fetchUser() -> CDUser? {
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Ошибка при получении пользователя: \(error)")
            return nil
        }
    }
}
