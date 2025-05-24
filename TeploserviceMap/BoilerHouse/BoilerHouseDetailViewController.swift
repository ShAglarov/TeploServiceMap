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
        self.focusMapOnUserLocation()
    }

    // MARK: - Загрузка домов котельной
    override func loadItems() {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        request.predicate = NSPredicate(format: "boilerHouse == %@", boilerHouse)
        do {
            items = try PersistenceController.shared.context.fetch(request)
            tableView.reloadData()
            reloadAnnotations()
        } catch {
            print("Ошибка загрузки домов котельной: \(error)")
        }
    }

    // MARK: - Аннотации на карте
    override func reloadAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        for point in items {
            let annotation = MKPointAnnotation()
            annotation.title = point.name
            annotation.coordinate = point.coordinate
            mapView.addAnnotation(annotation)
        }
        if !items.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: false)
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
            } catch {
                print("Ошибка сохранения дома: \(error)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Редактирование дома (универсальный для swipe)
    override func configureEditAlert(for item: SavedLocation, completion: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Редактировать дом", message: "Измените данные", preferredStyle: .alert)
        alert.addTextField { $0.text = item.name }
        alert.addTextField { $0.text = item.latitude == 0 ? "" : "\(item.latitude)" }
        alert.addTextField { $0.text = item.longitude == 0 ? "" : "\(item.longitude)" }
        alert.addTextField { $0.text = item.yearBuilt == 0 ? "" : "\(item.yearBuilt)" }
        alert.addTextField { $0.text = item.totalArea == 0 ? "" : "\(item.totalArea)" }
        alert.addTextField { $0.text = item.floors == 0 ? "" : "\(item.floors)" }
        alert.addTextField { $0.text = item.rooms == 0 ? "" : "\(item.rooms)" }
        alert.addTextField { $0.text = item.accounts == 0 ? "" : "\(item.accounts)" }
        alert.addTextField { $0.text = item.managementCompany }
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
            let fields = alert.textFields!
            item.name = fields[0].text ?? ""
            item.latitude = Double(fields[1].text ?? "") ?? 0
            item.longitude = Double(fields[2].text ?? "") ?? 0
            item.yearBuilt = Int32(fields[3].text ?? "") ?? 0
            item.totalArea = Double(fields[4].text ?? "") ?? 0
            item.floors = Int32(fields[5].text ?? "") ?? 0
            item.rooms = Int32(fields[6].text ?? "") ?? 0
            item.accounts = Int32(fields[7].text ?? "") ?? 0
            item.managementCompany = fields[8].text ?? ""
            do {
                try PersistenceController.shared.context.save()
                completion()
            } catch {
                print("Ошибка сохранения дома: \(error)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        return alert
    }

    // MARK: - Удаление дома (универсальный для swipe)
    override func handleDelete(item: SavedLocation, completion: @escaping () -> Void) {
        let context = PersistenceController.shared.context
        context.delete(item)
        do {
            try context.save()
            completion()
        } catch {
            print("Ошибка удаления дома: \(error)")
        }
    }

    // MARK: - Ячейка таблицы
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BaseCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "BaseCell")
        let point = items[indexPath.row]
        cell.textLabel?.text = point.name
        cell.detailTextLabel?.text = String(format: "Lat: %.4f, Lon: %.4f", point.latitude, point.longitude)
        return cell
    }

    // MARK: - Выделение на карте по строке
    override func focusMapOnItem(_ item: SavedLocation) {
        let region = MKCoordinateRegion(center: item.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0010, longitudeDelta: 0.0010))
        mapView.setRegion(region, animated: true)
        if let annotation = mapView.annotations.first(where: { ann in
            ann.coordinate.latitude == item.latitude && ann.coordinate.longitude == item.longitude
        }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }

    // MARK: - Long Press на строке: показать подробности
    override func handleLongPressOnItem(_ item: SavedLocation) {
        let alert = UIAlertController(title: item.name, message: "Lat: \(item.latitude)\nLon: \(item.longitude)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Долгое нажатие по карте — добавить дом
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
                } catch {
                    print("Ошибка сохранения дома: \(error)")
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        }
    }
}
