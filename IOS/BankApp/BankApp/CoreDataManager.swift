//
//  CoreDataManager.swift
//  BankApp
//
//  Created by Вадим Семибратов on 05.06.2025.
//

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
        
        do {
            try context.save()
            print("Ипотека успешно сохранена в CoreData")
            print("Saving mortgage with amount = \(amount)")

        } catch {
            print("Ошибка сохранения ипотеки: \(error)")
        }
    }
}
