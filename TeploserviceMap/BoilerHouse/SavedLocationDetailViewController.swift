//
//  File.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 26.05.2025.
//

import UIKit
import CoreLocation

class SavedLocationDetailViewController: UIViewController {
    private let savedLocation: SavedLocation

    // UI элементы
    private let stack = UIStackView()
    private let infoCard = UIView()
    private let lsButton = UIButton(type: .system)

    init(savedLocation: SavedLocation) {
        self.savedLocation = savedLocation
        super.init(nibName: nil, bundle: nil)
        self.title = savedLocation.name ?? "Дом"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        configureInfoCard()
        configureLSButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureLSButton()
    }

    private func setupLayout() {
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22)
        ])

        // Info card
        infoCard.backgroundColor = .secondarySystemBackground
        infoCard.layer.cornerRadius = 20
        infoCard.layer.shadowOpacity = 0.12
        infoCard.layer.shadowOffset = CGSize(width: 0, height: 3)
        infoCard.layer.shadowRadius = 10
        stack.addArrangedSubview(infoCard)
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

        // Лицевые счета кнопка
        lsButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        stack.addArrangedSubview(lsButton)
    }

    private func configureInfoCard() {
        let labels: [(String, String)] = [
            ("Название", savedLocation.name ?? ""),
            ("Этажей", "\(savedLocation.floors)"),
            ("Широта", "\(savedLocation.latitude)"),
            ("Долгота", "\(savedLocation.longitude)"),
            ("УК/УО", savedLocation.managementCompany ?? ""),
            ("Площадь", "\(savedLocation.totalArea)"),
            ("Год постройки", "\(savedLocation.yearBuilt)"),
            ("Помещений", "\(savedLocation.rooms)")
        ]

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 10
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 18),
            cardStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -18),
            cardStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -18)
        ])

        for (label, value) in labels {
            let hStack = UIStackView()
            hStack.axis = .horizontal
            hStack.distribution = .equalSpacing
            let keyLabel = UILabel()
            keyLabel.text = label
            keyLabel.font = .systemFont(ofSize: 16, weight: .regular)
            keyLabel.textColor = .secondaryLabel

            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.font = .systemFont(ofSize: 17, weight: .medium)
            valueLabel.textColor = .label

            hStack.addArrangedSubview(keyLabel)
            hStack.addArrangedSubview(valueLabel)
            cardStack.addArrangedSubview(hStack)
        }
    }

    private func configureLSButton() {
        let count = savedLocation.accountsCount 
        lsButton.setTitle("Лицевые счета: \(count)", for: .normal)
        lsButton.titleLabel?.font = .systemFont(ofSize: 19, weight: .bold)
        lsButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.09)
        lsButton.setTitleColor(.systemBlue, for: .normal)
        lsButton.layer.cornerRadius = 16
        lsButton.layer.shadowOpacity = 0.07
        lsButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        lsButton.layer.shadowRadius = 4

        lsButton.addTarget(self, action: #selector(showAccounts), for: .touchUpInside)
    }

    @objc private func showAccounts() {
        // Пушим экран со списком лицевых счетов
        let vc = AccountListViewController(savedLocation: savedLocation)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

class AccountListViewController: UITableViewController {
    private let savedLocation: SavedLocation
    private var accounts: [MyAccount] = []

    init(savedLocation: SavedLocation) {
        self.savedLocation = savedLocation
        super.init(style: .insetGrouped)
        self.title = "Лицевые счета"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAccount))
        loadAccounts()
    }

    private func loadAccounts() {
        if let set = savedLocation.myAccounts as? Set<MyAccount> {
            accounts = Array(set).sorted { ($0.accountNumber ?? "") < ($1.accountNumber ?? "") }
        } else {
            accounts = []
        }
        tableView.reloadData()
    }

    // Добавляем лицевой счет
    @objc private func addAccount() {
        let context = PersistenceController.shared.context
        let newAccount = MyAccount(context: context)
        newAccount.location = savedLocation
        let editVC = EditMyAccountViewController(account: newAccount, isNew: true)
        editVC.onSave = { [weak self] in
            self?.loadAccounts()
            // После сохранения закрываем модальное окно
            editVC.navigationController?.dismiss(animated: true)
        }
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)
        let acc = accounts[indexPath.row]
        cell.textLabel?.text = acc.accountNumber
        cell.detailTextLabel?.text = acc.fio
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // Открываем экран редактирования лицевых счетов модально
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let acc = accounts[indexPath.row]
        let editVC = EditMyAccountViewController(account: acc, isNew: false)
        editVC.onSave = { [weak self] in
            self?.loadAccounts()
        }
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true) // <-- и тут тоже открывается модально!
    }
}



extension SavedLocation {
    var accountsList: [MyAccount] {
        (myAccounts as? Set<MyAccount>)?.sorted { ($0.accountNumber ?? "") < ($1.accountNumber ?? "") } ?? []
    }
    var accountsCount: Int {
        accountsList.count
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
