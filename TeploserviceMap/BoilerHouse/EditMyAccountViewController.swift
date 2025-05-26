//
//  EditMyAccountViewController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 26.05.2025.
//

import UIKit

class EditMyAccountViewController: UITableViewController {

    private let account: MyAccount
    private let isNew: Bool
    var onSave: (() -> Void)?

    private var accountNumber: String
    private var fio: String
    private var area: Double
    private var status: String
    private var openDate: Date?
    private var closeDate: Date?
    private var phone: String
    private var email: String
    private var address: String

    init(account: MyAccount, isNew: Bool) {
        self.account = account
        self.isNew = isNew
        self.accountNumber = account.accountNumber ?? ""
        self.fio = account.fio ?? ""
        self.area = account.area
        self.status = account.status ?? ""
        self.openDate = account.openDate
        self.closeDate = account.closeDate
        self.phone = account.phone ?? ""
        self.email = account.email ?? ""
        self.address = account.address ?? ""
        super.init(style: .insetGrouped)
        self.title = isNew ? "Добавить ЛС" : "Редактировать ЛС"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FieldCell")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(saveTapped))
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 9 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FieldCell", for: indexPath)
        cell.selectionStyle = .none
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.textAlignment = .right
        tf.clearButtonMode = .whileEditing
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.addSubview(tf)
        NSLayoutConstraint.activate([
            tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            tf.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            tf.widthAnchor.constraint(equalToConstant: 160)
        ])
        cell.textLabel?.font = .systemFont(ofSize: 16)
        cell.textLabel?.textColor = .secondaryLabel
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Номер ЛС"
            tf.text = accountNumber
            tf.placeholder = "Введите номер"
            tf.addTarget(self, action: #selector(accountNumberChanged(_:)), for: .editingChanged)
        case 1:
            cell.textLabel?.text = "ФИО"
            tf.text = fio
            tf.placeholder = "Фамилия Имя Отчество"
            tf.addTarget(self, action: #selector(fioChanged(_:)), for: .editingChanged)
        case 2:
            cell.textLabel?.text = "Площадь"
            tf.keyboardType = .decimalPad
            tf.text = area == 0 ? "" : "\(area)"
            tf.placeholder = "50.0"
            tf.addTarget(self, action: #selector(areaChanged(_:)), for: .editingChanged)
        case 3:
            cell.textLabel?.text = "Статус"
            tf.text = status
            tf.placeholder = "Открыт/Закрыт"
            tf.addTarget(self, action: #selector(statusChanged(_:)), for: .editingChanged)
        case 4:
            cell.textLabel?.text = "Дата открытия"
            tf.text = openDate?.description ?? ""
            tf.placeholder = "01.01.2024"
            // date picker реализуй при необходимости
        case 5:
            cell.textLabel?.text = "Телефон"
            tf.text = phone
            tf.placeholder = "+7..."
            tf.addTarget(self, action: #selector(phoneChanged(_:)), for: .editingChanged)
        case 6:
            cell.textLabel?.text = "E-mail"
            tf.text = email
            tf.placeholder = "user@mail.com"
            tf.addTarget(self, action: #selector(emailChanged(_:)), for: .editingChanged)
        case 7:
            cell.textLabel?.text = "Адрес"
            tf.text = address
            tf.placeholder = "Адрес абонента"
            tf.addTarget(self, action: #selector(addressChanged(_:)), for: .editingChanged)
        default: break
        }
        tf.tag = indexPath.row
        return cell
    }

    // MARK: - Обработка изменений
    @objc private func accountNumberChanged(_ tf: UITextField) { accountNumber = tf.text ?? "" }
    @objc private func fioChanged(_ tf: UITextField) { fio = tf.text ?? "" }
    @objc private func areaChanged(_ tf: UITextField) { area = Double(tf.text ?? "") ?? 0 }
    @objc private func statusChanged(_ tf: UITextField) { status = tf.text ?? "" }
    @objc private func phoneChanged(_ tf: UITextField) { phone = tf.text ?? "" }
    @objc private func emailChanged(_ tf: UITextField) { email = tf.text ?? "" }
    @objc private func addressChanged(_ tf: UITextField) { address = tf.text ?? "" }

    @objc private func saveTapped() {
        account.accountNumber = accountNumber
        account.fio = fio
        account.area = area
        account.status = status
        account.openDate = openDate
        account.closeDate = closeDate
        account.phone = phone
        account.email = email
        account.address = address

        do {
            try account.managedObjectContext?.save()
            onSave?()
            // Закрываем модальное окно
            self.navigationController?.dismiss(animated: true)
        } catch {
            let alert = UIAlertController(title: "Ошибка", message: "Не удалось сохранить лицевой счет.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    @objc private func cancelTapped() {
        if isNew {
            account.managedObjectContext?.delete(account)
        }
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
