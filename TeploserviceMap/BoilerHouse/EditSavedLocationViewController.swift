//
//  EditSavedLocationViewController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 25.05.2025.
//
import UIKit
import CoreData

class EditSavedLocationViewController: UITableViewController {

    private let savedLocation: SavedLocation
    private let isNew: Bool
    var onSave: (() -> Void)?

    // Временные переменные для редактирования
    private var name: String
    private var latitude: Double
    private var longitude: Double
    private var yearBuilt: Int32
    private var totalArea: Double
    private var floors: Int32
    private var rooms: Int32
    private var managementCompany: String

    init(savedLocation: SavedLocation, isNew: Bool) {
        self.savedLocation = savedLocation
        self.isNew = isNew
        self.name = savedLocation.name ?? ""
        self.latitude = savedLocation.latitude
        self.longitude = savedLocation.longitude
        self.yearBuilt = savedLocation.yearBuilt
        self.totalArea = savedLocation.totalArea
        self.floors = savedLocation.floors
        self.rooms = savedLocation.rooms
        self.managementCompany = savedLocation.managementCompany ?? ""
        super.init(style: .insetGrouped)
        self.title = isNew ? "Добавить дом" : "Редактировать дом"
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
            cell.textLabel?.text = "Название"
            tf.text = name
            tf.placeholder = "Введите название"
            tf.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)
        case 1:
            cell.textLabel?.text = "Широта"
            tf.keyboardType = .decimalPad
            tf.text = latitude == 0 ? "" : "\(latitude)"
            tf.placeholder = "42.000000"
            tf.addTarget(self, action: #selector(latitudeChanged(_:)), for: .editingChanged)
        case 2:
            cell.textLabel?.text = "Долгота"
            tf.keyboardType = .decimalPad
            tf.text = longitude == 0 ? "" : "\(longitude)"
            tf.placeholder = "47.000000"
            tf.addTarget(self, action: #selector(longitudeChanged(_:)), for: .editingChanged)
        case 3:
            cell.textLabel?.text = "Год постройки"
            tf.keyboardType = .numberPad
            tf.text = yearBuilt == 0 ? "" : "\(yearBuilt)"
            tf.placeholder = "2020"
            tf.addTarget(self, action: #selector(yearBuiltChanged(_:)), for: .editingChanged)
        case 4:
            cell.textLabel?.text = "Площадь"
            tf.keyboardType = .decimalPad
            tf.text = totalArea == 0 ? "" : "\(totalArea)"
            tf.placeholder = "150.0"
            tf.addTarget(self, action: #selector(totalAreaChanged(_:)), for: .editingChanged)
        case 5:
            cell.textLabel?.text = "Этажей"
            tf.keyboardType = .numberPad
            tf.text = floors == 0 ? "" : "\(floors)"
            tf.placeholder = "5"
            tf.addTarget(self, action: #selector(floorsChanged(_:)), for: .editingChanged)
        case 6:
            cell.textLabel?.text = "Помещений"
            tf.keyboardType = .numberPad
            tf.text = rooms == 0 ? "" : "\(rooms)"
            tf.placeholder = "10"
            tf.addTarget(self, action: #selector(roomsChanged(_:)), for: .editingChanged)
        case 7:
            cell.textLabel?.text = "УК/УО"
            tf.text = managementCompany
            tf.placeholder = "Название УК/УО"
            tf.addTarget(self, action: #selector(managementCompanyChanged(_:)), for: .editingChanged)
        case 8:
            if indexPath.row == 8 {
                cell.textLabel?.text = "Лицевые счета"
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        default:
            break
        }
        tf.tag = indexPath.row
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 8 {
            let accountsVC = MyAccountsListViewController(savedLocation: savedLocation)
            navigationController?.pushViewController(accountsVC, animated: true)
        }
    }

    // MARK: - Обработка изменений
    @objc private func nameChanged(_ tf: UITextField) { name = tf.text ?? "" }
    @objc private func latitudeChanged(_ tf: UITextField) { latitude = Double(tf.text ?? "") ?? 0 }
    @objc private func longitudeChanged(_ tf: UITextField) { longitude = Double(tf.text ?? "") ?? 0 }
    @objc private func yearBuiltChanged(_ tf: UITextField) { yearBuilt = Int32(tf.text ?? "") ?? 0 }
    @objc private func totalAreaChanged(_ tf: UITextField) { totalArea = Double(tf.text ?? "") ?? 0 }
    @objc private func floorsChanged(_ tf: UITextField) { floors = Int32(tf.text ?? "") ?? 0 }
    @objc private func roomsChanged(_ tf: UITextField) { rooms = Int32(tf.text ?? "") ?? 0 }
    @objc private func managementCompanyChanged(_ tf: UITextField) { managementCompany = tf.text ?? "" }

    @objc private func saveTapped() {
        savedLocation.name = name
        savedLocation.latitude = latitude
        savedLocation.longitude = longitude
        savedLocation.yearBuilt = yearBuilt
        savedLocation.totalArea = totalArea
        savedLocation.floors = floors
        savedLocation.rooms = rooms
        savedLocation.managementCompany = managementCompany

        do {
            try savedLocation.managedObjectContext?.save()
            onSave?()
            // Закрываем модальное окно (NaviController с этим VC)
            self.navigationController?.dismiss(animated: true, completion: nil)
        } catch {
            let alert = UIAlertController(title: "Ошибка", message: "Не удалось сохранить дом.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    @objc private func cancelTapped() {
        if isNew, let context = savedLocation.managedObjectContext {
            // Удаляем временный объект (он только что был создан)
            context.delete(savedLocation)
            try? context.save()
        }
        dismiss(animated: true)
    }
}
