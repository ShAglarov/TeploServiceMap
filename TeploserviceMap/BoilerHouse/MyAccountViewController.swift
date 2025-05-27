//
//  MyAccountViewController.swift
//  TeploserviceMap
//
//  Created by KazbekMusaev on 26.05.2025.
//

import UIKit

final class MyAccountViewController: UIViewController {

    var savedLocation: SavedLocation = SavedLocation()
    private var accounts: [MyAccount] = []
    private var filteredAccounts: [MyAccount] = []
    private var isLoading = false
    
    //MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        settupView()
        loadAccounts()
    }
    
    //MARK: - Functions
    private func settupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAccountTapped))
        navigationItem.title = "Лицевые счета"
        view.addSubview(accountsTabelView)
        NSLayoutConstraint.activate([
            accountsTabelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            accountsTabelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            accountsTabelView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            accountsTabelView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadAccounts() {
        accounts = savedLocation.accountsList
        filteredAccounts = accounts
        accountsTabelView.reloadData()
    }
    
    //MARK: - View elements
    private lazy var accountsTabelView: UITableView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.delegate = self
        $0.dataSource = self
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCell")
        return $0
    }(UITableView())
    
    //MARK: - Actions
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

extension MyAccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        guard !isLoading else { return nil }

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
        deleteAction.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension MyAccountViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredAccounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)
        let acc = filteredAccounts[indexPath.row]
        cell.textLabel?.text = acc.fio ?? acc.accountNumber ?? "ЛС"
        cell.detailTextLabel?.text = acc.status
        return cell
    }
}
