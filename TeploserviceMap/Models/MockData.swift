//
//  File.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 25.05.2025.
//

import Foundation

struct MockData {
    static func sampleAccounts() -> [Account] {
        return [
            Account(
                accountNumber: "000001",
                fio: "Иванов И.И.",
                address: "ул. Ленина, д. 12, кв. 34",
                phone: "+7 (928) 123-45-67",
                email: "ivanov@example.com",
                openDate: Date(timeIntervalSince1970: 1609459200),
                closeDate: nil,
                customerType: .individual,
                area: 45.0,
                residentsCount: 2,
                status: .opened,
                statusReason: nil,
                serviceCompany: "ООО Махачкалатеплосервис",
                serviceTypes: [.hotWater, .heating, .coldWater],
                debt: 850.50,
                owner: "Иванов И.И.",
                docNumber: "82 12 123456",
                lastPaymentDate: Date(),
                note: "Постоянная скидка"
            ),
            Account(
                accountNumber: "000002",
                fio: "Петров П.П.",
                address: "ул. Ленина, д. 12, кв. 35",
                phone: "+7 (928) 765-43-21",
                email: "petrov@example.com",
                openDate: Date(timeIntervalSince1970: 1612137600),
                closeDate: nil,
                customerType: .individual,
                area: 60.0,
                residentsCount: 3,
                status: .opened,
                statusReason: nil,
                serviceCompany: "ООО Махачкалатеплосервис",
                serviceTypes: [.heating, .coldWater],
                debt: 120.00,
                owner: "Петров П.П.",
                docNumber: "82 12 654321",
                lastPaymentDate: Date(),
                note: "Оплата вовремя"
            )
        ]
    }
}
