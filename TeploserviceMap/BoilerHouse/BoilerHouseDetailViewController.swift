//
//  HousesViewController.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 23.05.2025.
//

import UIKit
import MapKit
import CoreData

class BoilerHouseDetailViewController: BaseMapListViewController<SavedLocation> {

    private var boilerHouse: BoilerHouse

    // MARK: - Инициализация
    init(boilerHouse: BoilerHouse) {
        self.boilerHouse = boilerHouse
        super.init(nibName: nil, bundle: nil)
        self.title = boilerHouse.name
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()
        addSavedPointsToMap()
    }

    // MARK: - Загрузка домов котельной
    override func loadItems() {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        request.predicate = NSPredicate(format: "boilerHouse == %@", boilerHouse)
        do {
            items = try PersistenceController.shared.context.fetch(request)
            tableView.reloadData()
            addSavedPointsToMap()
        } catch {
            print("Ошибка загрузки домов котельной: \(error)")
        }
    }

    // MARK: - Добавить дом
    override func showAddItemAlert() {
        let alert = UIAlertController(title: "Добавить дом", message: "Введите характеристики дома", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addTextField { $0.placeholder = "Широта" }
        alert.addTextField { $0.placeholder = "Долгота" }
        alert.addTextField { $0.placeholder = "Год постройки (например, 2000)" }
        alert.addTextField { $0.placeholder = "Общая площадь (кв.м.)" }
        alert.addTextField { $0.placeholder = "Этажей" }
        alert.addTextField { $0.placeholder = "Помещений" }
        alert.addTextField { $0.placeholder = "Лицевых счетов" }
        alert.addTextField { $0.placeholder = "Управляющая организация" }
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
            let fields = alert.textFields!
            let name = fields[0].text ?? ""
            let latitude = Double(fields[1].text ?? "") ?? 0
            let longitude = Double(fields[2].text ?? "") ?? 0
            let yearBuilt = Int32(fields[3].text ?? "") ?? 0
            let totalArea = Double(fields[4].text ?? "") ?? 0
            let floors = Int32(fields[5].text ?? "") ?? 0
            let rooms = Int32(fields[6].text ?? "") ?? 0
            let accounts = Int32(fields[7].text ?? "") ?? 0
            let managementCompany = fields[8].text ?? ""
            let context = PersistenceController.shared.context
            let newHouse = SavedLocation(context: context)
            newHouse.name = name
            newHouse.latitude = latitude
            newHouse.longitude = longitude
            newHouse.yearBuilt = yearBuilt
            newHouse.totalArea = totalArea
            newHouse.floors = floors
            newHouse.rooms = rooms
            newHouse.accounts = accounts
            newHouse.managementCompany = managementCompany
            newHouse.boilerHouse = self.boilerHouse
            do {
                try context.save()
                self.loadItems()
                self.addSavedPointsToMap()
            } catch {
                print("Ошибка сохранения дома: \(error)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Отображение домов на карте
    func addSavedPointsToMap() {
        mapView.removeAnnotations(mapView.annotations)
        for item in items {
            guard let point = item as? SavedLocation else { continue }
            let annotation = MKPointAnnotation()
            annotation.title = point.name
            annotation.coordinate = point.coordinate
            mapView.addAnnotation(annotation)
        }
        if !items.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: false)
        }
    }

    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BaseCell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "BaseCell")
        guard let point = items[indexPath.row] as? SavedLocation else { return cell }
        cell.textLabel?.text = point.name
        cell.detailTextLabel?.text = String(format: "Lat: %.4f, Lon: %.4f", point.latitude, point.longitude)
        return cell
    }

    // MARK: - Редактирование и удаление свайпом
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal, title: "Редакт.") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            guard let point = self.items[indexPath.row] as? SavedLocation else { return }
            let alert = UIAlertController(title: "Редактировать дом", message: "Измените данные", preferredStyle: .alert)
            alert.addTextField { $0.text = point.name }
            alert.addTextField { $0.text = "\(point.latitude)" }
            alert.addTextField { $0.text = "\(point.longitude)" }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                let fields = alert.textFields!
                point.name = fields[0].text ?? ""
                point.latitude = Double(fields[1].text ?? "") ?? 0
                point.longitude = Double(fields[2].text ?? "") ?? 0
                do {
                    try PersistenceController.shared.context.save()
                    self.loadItems()
                    self.addSavedPointsToMap()
                } catch {
                    print("Ошибка сохранения: \(error)")
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alert, animated: true)
            completionHandler(true)
        }
        edit.backgroundColor = .orange

        let delete = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let context = PersistenceController.shared.context
            let toDelete = self.items[indexPath.row]
            context.delete(toDelete)
            do {
                try context.save()
                self.loadItems()
                self.addSavedPointsToMap()
            } catch {
                print("Ошибка удаления дома: \(error)")
            }
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [delete, edit])
    }

    // MARK: - Tap по строке таблицы: центрирование карты + выделение аннотации
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let point = items[indexPath.row] as? SavedLocation else { return }
        let region = MKCoordinateRegion(center: point.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0010, longitudeDelta: 0.0010))
        mapView.setRegion(region, animated: true)
        if let annotation = mapView.annotations.first(where: { ann in
            ann.coordinate.latitude == point.latitude && ann.coordinate.longitude == point.longitude
        }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Долгое нажатие по строке: показать подробности
    override func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              gesture.state == .began else { return }

        guard let house = items[indexPath.row] as? SavedLocation else { return }
        let alert = UIAlertController(title: house.name, message: "Lat: \(house.latitude)\nLon: \(house.longitude)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Добавление дома по долгому нажатию на карту
    override func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: mapView)
            let coord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let alert = UIAlertController(title: "Новый дом", message: "Введите характеристики дома", preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Название" }
            alert.addTextField { $0.placeholder = "Год постройки (например, 2000)" }
            alert.addTextField { $0.placeholder = "Общая площадь (кв.м.)" }
            alert.addTextField { $0.placeholder = "Этажей" }
            alert.addTextField { $0.placeholder = "Помещений" }
            alert.addTextField { $0.placeholder = "Лицевых счетов" }
            alert.addTextField { $0.placeholder = "Управляющая организация" }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                let fields = alert.textFields!
                let name = fields[0].text ?? ""
                let yearBuilt = Int32(fields[1].text ?? "") ?? 0
                let totalArea = Double(fields[2].text ?? "") ?? 0
                let floors = Int32(fields[3].text ?? "") ?? 0
                let rooms = Int32(fields[4].text ?? "") ?? 0
                let accounts = Int32(fields[5].text ?? "") ?? 0
                let managementCompany = fields[6].text ?? ""
                let context = PersistenceController.shared.context
                let newHouse = SavedLocation(context: context)
                newHouse.name = name
                newHouse.latitude = coord.latitude
                newHouse.longitude = coord.longitude
                newHouse.yearBuilt = yearBuilt
                newHouse.totalArea = totalArea
                newHouse.floors = floors
                newHouse.rooms = rooms
                newHouse.accounts = accounts
                newHouse.managementCompany = managementCompany
                newHouse.boilerHouse = self.boilerHouse
                do {
                    try context.save()
                    self.loadItems()
                    self.addSavedPointsToMap()
                } catch {
                    print("Ошибка сохранения дома: \(error)")
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        }
    }

    // MARK: - Карточка аннотаций (если нужно, можешь кастомизировать)
    // override func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? { ... }
}
