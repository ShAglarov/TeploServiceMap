//
//  Account.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 25.05.2025.
//

import Foundation

struct Account: Hashable {
    /// Тип абонента
    enum CustomerType: String, Codable {
        case individual = "Физическое лицо"
        case legalEntity = "Юридическое лицо"
        case soleTrader = "Индивидуальный предприниматель"
    }

    /// Статус счета
    enum AccountStatus: String, Codable {
        case opened = "Открыт"
        case closed = "Закрыт"
        case suspended = "Временно отключён"
        case blocked = "Блокирован"
        case debtCollection = "Передан в работу по взысканию"
    }

    /// Вид коммунальной услуги
    enum ServiceType: String, Codable {
        case hotWater = "ГВС"
        case coldWater = "ХВС"
        case heating = "Отопление"
        case electricity = "Электроэнергия"
        case gas = "Газ"
        case sewerage = "Канализация"
        case garbage = "Вывоз ТКО"
        case internet = "Интернет"
    }

    /// Уникальный номер лицевого счета
    let accountNumber: String

    /// ФИО абонента (собственник/наниматель/пользователь)
    let fio: String

    /// Адрес объекта (квартира, помещение)
    let address: String

    /// Контактный телефон абонента
    let phone: String?

    /// Email для связи
    let email: String?

    /// Дата открытия лицевого счета
    let openDate: Date

    /// Дата закрытия (если счет закрыт)
    let closeDate: Date?

    /// Тип абонента (физлицо, юрлицо, ИП)
    let customerType: CustomerType

    /// Общая площадь, на которую начисляется плата
    let area: Double

    /// Количество проживающих/зарегистрированных (для расчётов)
    let residentsCount: Int?

    /// Статус счета (открыт, временно отключен, закрыт, блокирован и т.д.)
    let status: AccountStatus

    /// Причина закрытия/блокировки (если есть)
    let statusReason: String?

    /// Название управляющей/ресурсоснабжающей компании
    let serviceCompany: String?

    /// Вид коммунальных услуг (ГВС, ХВС, отопление, свет, газ и т.д.)
    let serviceTypes: [ServiceType]

    /// Текущая задолженность по счету
    let debt: Double?

    /// Лицо, на которое оформлен счет (может отличаться от проживающего)
    let owner: String?

    /// Номер документа, удостоверяющего личность (паспорт, ИНН)
    let docNumber: String?

    /// Дата последнего начисления/оплаты
    let lastPaymentDate: Date?

    /// Примечание (свободное поле)
    let note: String?
}
