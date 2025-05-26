//
//  MyAccountsListViewController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 26.05.2025.
//

import UIKit

class MyAccountsListViewController: UITableViewController {

    private let savedLocation: SavedLocation
    private var accounts: [MyAccount] = []
    private var filteredAccounts: [MyAccount] = []
    private var isLoading = false

    init(savedLocation: SavedLocation) {
        self.savedLocation = savedLocation
        super.init(style: .insetGrouped)
        self.title = "Лицевые счета"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAccountTapped))
        loadAccounts()
    }

    private func loadAccounts() {
        accounts = savedLocation.accountsList
        filteredAccounts = accounts
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredAccounts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)
        let acc = filteredAccounts[indexPath.row]
        cell.textLabel?.text = acc.fio ?? acc.accountNumber ?? "ЛС"
        cell.detailTextLabel?.text = acc.status
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isLoading else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] (_, _, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }

            let accountToDelete = self.filteredAccounts[indexPath.row]
            guard let context = accountToDelete.managedObjectContext else {
                completionHandler(false)
                return
            }

            context.delete(accountToDelete)

            do {
                try context.save()

                if let indexInAccounts = self.accounts.firstIndex(of: accountToDelete) {
                    self.accounts.remove(at: indexInAccounts)
                }

                self.filteredAccounts.remove(at: indexPath.row)

                tableView.deleteRows(at: [indexPath], with: .automatic)

                completionHandler(true)
            } catch {
                completionHandler(false)
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось удалить лицевой счет.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    @objc private func addAccountTapped() {
        let context = PersistenceController.shared.context
        let newAccount = MyAccount(context: context)
        newAccount.location = savedLocation

        let editVC = EditMyAccountViewController(account: newAccount, isNew: true)
        editVC.onSave = { [weak self] in
            self?.loadAccounts()
            self?.dismiss(animated: true)
        }
        let nav = UINavigationController(rootViewController: editVC)
        present(nav, animated: true)
    }
}
