//
//  File.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 26.05.2025.
//

import UIKit
import CoreData

enum SearchCategory: Int, CaseIterable, CustomStringConvertible {
    case all, accountNumber, fio, managementCompany, address
    
    var displayName: String {
        switch self {
        case .all: return "По всем полям"
        case .accountNumber: return "По номеру ЛС"
        case .fio: return "По ФИО"
        case .managementCompany: return "По УК/УО"
        case .address: return "По адресу"
        }
    }
    
    var description: String { displayName }
}

class SearchCategoryViewController: UITableViewController {
    var onCategorySelected: ((SearchCategory) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
    }

    private func setupHeader() {
        let headerLabel = UILabel()
        headerLabel.text = "Поиск по критериям"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textColor = .label
        headerLabel.textAlignment = .center
        headerLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
        tableView.tableHeaderView = headerLabel
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SearchCategory.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = SearchCategory.allCases[indexPath.row]
        cell.textLabel?.text = category.displayName
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let category = SearchCategory.allCases[indexPath.row]
        onCategorySelected?(category)
    }
}

class AccountsSearchViewController: UITableViewController, UISearchBarDelegate {
    private let category: SearchCategory
    private var results: [MyAccount] = []
    private let searchBar = UISearchBar()

    init(category: SearchCategory) {
        self.category = category
        super.init(style: .insetGrouped)
        self.title = "Поиск: \(category.displayName)"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ResultCell")
        setupSearchBar()
        setupHeader()
    }

    private func setupHeader() {
        let headerLabel = UILabel()
        headerLabel.text = "Поиск: \(category.displayName)"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textColor = .label
        headerLabel.textAlignment = .center
        headerLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
        tableView.tableHeaderView = headerLabel
    }

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Введите значение"
        searchBar.autocapitalizationType = .none
        navigationItem.titleView = searchBar
        searchBar.becomeFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(query: searchText)
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            results = []
            tableView.reloadData()
            return
        }
        let request: NSFetchRequest<MyAccount> = MyAccount.fetchRequest()
        request.fetchLimit = 50 // не обязательно, но для оптимизации

        var predicate: NSPredicate

        switch category {
        case .accountNumber:
            predicate = NSPredicate(format: "accountNumber CONTAINS[cd] %@", query)
        case .fio:
            predicate = NSPredicate(format: "fio CONTAINS[cd] %@", query)
        case .managementCompany:
            predicate = NSPredicate(format: "location.managementCompany CONTAINS[cd] %@", query)
        case .address:
            predicate = NSPredicate(format: "address CONTAINS[cd] %@", query)
        case .all:
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "accountNumber CONTAINS[cd] %@", query),
                NSPredicate(format: "fio CONTAINS[cd] %@", query),
                NSPredicate(format: "location.managementCompany CONTAINS[cd] %@", query),
                NSPredicate(format: "address CONTAINS[cd] %@", query),
                NSPredicate(format: "location.name CONTAINS[cd] %@", query)
            ])
        }

        request.predicate = predicate

        do {
            let context = PersistenceController.shared.context
            results = try context.fetch(request)
            tableView.reloadData()
            print("Результатов поиска: \(results.count)")
        } catch {
            print("Ошибка поиска: \(error)")
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { results.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        let acc = results[indexPath.row]
        cell.textLabel?.text = "\(acc.accountNumber ?? "—") | \(acc.fio ?? "")"
        cell.detailTextLabel?.text = acc.address ?? ""
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let acc = results[indexPath.row]
        let editVC = EditMyAccountViewController(account: acc, isNew: false)
        navigationController?.pushViewController(editVC, animated: true)
    }
}
