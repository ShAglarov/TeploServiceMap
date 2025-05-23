//
//  HousesViewController.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 23.05.2025.
//

import UIKit

class HousesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView()
    private var boilerHouse: BoilerHouse
    private var houses: [SavedLocation] = []

    init(boilerHouse: BoilerHouse) {
        self.boilerHouse = boilerHouse
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = boilerHouse.name ?? "Дома котельной"
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HouseCell")

        // Можно добавить кнопку "добавить дом"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addHouseTapped))

        loadHouses()
    }

    private func loadHouses() {
        if let set = boilerHouse.locations as? Set<SavedLocation> {
            houses = Array(set)
            tableView.reloadData()
        } else {
            houses = []
        }
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return houses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HouseCell", for: indexPath)
        let house = houses[indexPath.row]
        cell.textLabel?.text = house.name
        return cell
    }

    // MARK: - TableView Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Открывать детали дома, если понадобится:
        // let selectedHouse = houses[indexPath.row]
        // presentEditDetailsAlert(for: selectedHouse)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // Удаление дома (по свайпу, если понадобится)
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = PersistenceController.shared.context
            let houseToDelete = houses[indexPath.row]
            context.delete(houseToDelete)
            do {
                try context.save()
                loadHouses()
            } catch {
                print("Ошибка удаления дома: \(error)")
            }
        }
    }

    // Добавление дома (через alert, можно расширить)
    @objc private func addHouseTapped() {
        let alert = UIAlertController(title: "Новый дом", message: "Введите название дома", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { [weak self] _ in
            guard let self = self, let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            let context = PersistenceController.shared.context
            let newHouse = SavedLocation(context: context)
            newHouse.name = text
            newHouse.boilerHouse = self.boilerHouse // ВАЖНО: связываем с котельной
            do {
                try context.save()
                self.loadHouses()
            } catch {
                print("Ошибка сохранения дома: \(error)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}
