//
//  AccountDetailViewController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 26.05.2025.
//

import UIKit

class AccountDetailViewController: UIViewController {
    private let account: Account

    init(account: Account) {
        self.account = account
        super.init(nibName: nil, bundle: nil)
        self.title = "Лицевой счет"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])

        func info(_ label: String, _ value: String) -> UILabel {
            let l = UILabel()
            l.numberOfLines = 0
            l.font = .systemFont(ofSize: 16)
            l.textColor = .label
            l.text = "\(label): \(value)"
            return l
        }

        stack.addArrangedSubview(info("Номер счета", account.accountNumber))
        stack.addArrangedSubview(info("ФИО абонента", account.fio))
        stack.addArrangedSubview(info("Площадь", "\(account.area) м²"))
        stack.addArrangedSubview(info("Статус", account.status.rawValue))
    }
}
