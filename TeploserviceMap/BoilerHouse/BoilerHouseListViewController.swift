//
//  File.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 23.05.2025.
//

import UIKit
import MapKit
import CoreData

class BoilerHouseListViewController: BaseMapListViewController<BoilerHouse> {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Котельные"
        loadItems()
        self.focusMapOnUserLocation()
    }

    // MARK: - Загрузка котельных
    override func loadItems() {
        let request: NSFetchRequest<BoilerHouse> = BoilerHouse.fetchRequest()
        do {
            items = try PersistenceController.shared.context.fetch(request)
            tableView.reloadData()
            reloadAnnotations()
        } catch {
            print("Ошибка загрузки котельных: \(error)")
        }
    }

    // MARK: - Аннотации на карту
    override func reloadAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        for boiler in items {
            guard boiler.latitude != 0, boiler.longitude != 0 else { continue }
            let annotation = MKPointAnnotation()
            annotation.title = boiler.name ?? "Без названия"
            annotation.coordinate = CLLocationCoordinate2D(latitude: boiler.latitude, longitude: boiler.longitude)
            mapView.addAnnotation(annotation)
        }
        if !items.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: false)
        }
    }

    // MARK: - Добавить котельную
    override func showAddItemAlert() {
        let alert = UIAlertController(title: "Добавить котельную", message: "Введите название и координаты", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addTextField { $0.placeholder = "Широта" }
        alert.addTextField { $0.placeholder = "Долгота" }
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
            let fields = alert.textFields!
            let name = fields[0].text ?? ""
            let latitude = Double(fields[1].text ?? "") ?? 0
            let longitude = Double(fields[2].text ?? "") ?? 0
            let context = PersistenceController.shared.context
            let newBoiler = BoilerHouse(context: context)
            newBoiler.name = name
            newBoiler.latitude = latitude
            newBoiler.longitude = longitude
            do {
                try context.save()
                self.loadItems()
            } catch {
                print("Ошибка сохранения котельной: \(error)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Swipe: редактирование
    override func configureEditAlert(for item: BoilerHouse, completion: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Редактировать котельную", message: "Измените название или координаты", preferredStyle: .alert)
        alert.addTextField { $0.text = item.name }
        alert.addTextField { $0.text = item.latitude == 0 ? "" : "\(item.latitude)" }
        alert.addTextField { $0.text = item.longitude == 0 ? "" : "\(item.longitude)" }
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
            let fields = alert.textFields!
            item.name = fields[0].text ?? ""
            item.latitude = Double(fields[1].text ?? "") ?? 0
            item.longitude = Double(fields[2].text ?? "") ?? 0
            do {
                try PersistenceController.shared.context.save()
                completion()
            } catch {
                print("Ошибка сохранения котельной: \(error)")
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        return alert
    }

    // MARK: - Swipe: удаление
    override func handleDelete(item: BoilerHouse, completion: @escaping () -> Void) {
        let context = PersistenceController.shared.context
        context.delete(item)
        do {
            try context.save()
            completion()
        } catch {
            print("Ошибка удаления котельной: \(error)")
        }
    }

    // MARK: - Выделение на карте по строке
    override func focusMapOnItem(_ item: BoilerHouse) {
        let coord = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
        let region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.0010, longitudeDelta: 0.0010))
        mapView.setRegion(region, animated: true)
        if let annotation = mapView.annotations.first(where: { ann in
            ann.coordinate.latitude == item.latitude && ann.coordinate.longitude == item.longitude
        }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }

    // MARK: - Long press по строке
    override func handleLongPressOnItem(_ item: BoilerHouse) {
        let detailVC = BoilerHouseDetailViewController(boilerHouse: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Ячейка
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let boiler = items[indexPath.row]
        cell.textLabel?.text = boiler.name ?? "Без названия"
        cell.detailTextLabel?.text = String(format: "Lat: %.4f, Lon: %.4f", boiler.latitude, boiler.longitude)
        return cell
    }

    // MARK: - Долгое нажатие по карте (добавить котельную)
    override func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: mapView)
            let coord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let alert = UIAlertController(title: "Новая котельная", message: "Введите название котельной", preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Название" }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                let name = alert.textFields?.first?.text ?? ""
                let context = PersistenceController.shared.context
                let newBoiler = BoilerHouse(context: context)
                newBoiler.name = name
                newBoiler.latitude = coord.latitude
                newBoiler.longitude = coord.longitude
                do {
                    try context.save()
                    self.loadItems()
                } catch {
                    print("Ошибка сохранения котельной: \(error)")
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        }
    }
}
