//
//  File.swift
//  TeploserviceMap
//
//  Created Shamil Aglarov on 23.05.2025.
//

import UIKit
import MapKit
import CoreData
import UniformTypeIdentifiers

class BoilerHouseListViewController: BaseMapListViewController<BoilerHouse> {

    override func importItemsFromJSON() {
        let fm = FileManager.default
        let jsonURL = FileManager.default.temporaryDirectory.appendingPathComponent("boilerhouses.json")
        guard fm.fileExists(atPath: jsonURL.path) else {
            showAlert(title: "Файл не найден", message: "Сначала экспортируйте объекты или скопируйте boilerhouses.json в приложение.")
            return
        }
        importFromJSON(jsonURL)
    }

    // MARK: - Загрузка котельных из Core Data
    override func loadItems() {
        let request = NSFetchRequest<BoilerHouse>(entityName: "BoilerHouse")
        do {
            items = try PersistenceController.shared.context.fetch(request)
            tableView.reloadData()
            reloadAnnotations()
        } catch {
            print("Ошибка загрузки котельных: \(error)")
        }
    }

    // MARK: - Отображение аннотаций на карте
    override func reloadAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
        for boiler in items {
            let annotation = MKPointAnnotation()
            annotation.title = boiler.name ?? "Без названия"
            annotation.coordinate = CLLocationCoordinate2D(latitude: boiler.latitude, longitude: boiler.longitude)
            mapView.addAnnotation(annotation)
            if let savedSet = boiler.savedLocations as? Set<SavedLocation> {
                for loc in savedSet {
                    let locAnnotation = MKPointAnnotation()
                    locAnnotation.title = loc.name
                    locAnnotation.coordinate = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                    mapView.addAnnotation(locAnnotation)
                }
            }
        }
        if !items.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: false)
        }
    }

    // MARK: - Добавить котельную (Alert)
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

    // MARK: - Редактирование котельной (Alert)
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

    // MARK: - Удаление котельной
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

    // MARK: - Выделение котельной на карте
    override func focusMapOnItem(_ item: BoilerHouse) {
        let coord = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
        let region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
        mapView.setRegion(region, animated: true)
        if let annotation = mapView.annotations.first(where: { ann in
            ann.coordinate.latitude == item.latitude && ann.coordinate.longitude == item.longitude
        }) {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }

    // MARK: - Долгое нажатие по строке — подробности котельной
    override func handleLongPressOnItem(_ item: BoilerHouse) {
        let detailVC = BoilerHouseDetailViewController(boilerHouse: item)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Ячейка таблицы
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let boiler = items[indexPath.row]
        cell.textLabel?.text = boiler.name ?? "Без названия"
        cell.detailTextLabel?.text = String(format: "Lat: %.4f, Lon: %.4f", boiler.latitude, boiler.longitude)
        return cell
    }

    // MARK: - Долгое нажатие по карте — добавить котельную
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

    // --- ЭКСПОРТ ---
    func exportBoilerHouses() {
        let context = PersistenceController.shared.context
        do {
            let request = NSFetchRequest<BoilerHouse>(entityName: "BoilerHouse")
            let boilerhouses = try context.fetch(request)
            let exportData: [BoilerHouseData] = boilerhouses.map { bh in
                let savedList = (bh.savedLocations as? Set<SavedLocation>) ?? []
                let savedLocationsData = savedList.map { sl in
                    SavedLocationData(
                        name: sl.name ?? "",
                        latitude: sl.latitude,
                        longitude: sl.longitude,
                        floors: sl.floors == 0 ? nil : Int(sl.floors),
                        yearBuilt: sl.yearBuilt == 0 ? nil : Int(sl.yearBuilt),
                        rooms: sl.rooms == 0 ? nil : Int(sl.rooms),
                        accounts: sl.accounts == 0 ? nil : Int(sl.accounts),
                        totalArea: sl.totalArea == 0 ? nil : sl.totalArea,
                        managementCompany: sl.managementCompany
                    )
                }
                return BoilerHouseData(
                    name: bh.name ?? "",
                    latitude: bh.latitude,
                    longitude: bh.longitude,
                    savedLocations: savedLocationsData
                )
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(exportData)
            let tmpDir = FileManager.default.temporaryDirectory
            let fileURL = tmpDir.appendingPathComponent("boilerhouses.json")
            try jsonData.write(to: fileURL, options: .atomic)
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            present(activityVC, animated: true, completion: nil)
        } catch {
            print("Ошибка экспорта: \(error)")
            showAlert(title: "Ошибка экспорта", message: error.localizedDescription)
        }
    }

    override func exportItemsToJSON() {
        exportBoilerHouses()
    }

    // --- ИМПОРТ ---
    func importBoilerHouses() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        picker.modalPresentationStyle = .formSheet
        present(picker, animated: true, completion: nil)
    }

    override func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        importFromJSON(fileURL)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    private func importFromJSON(_ fileURL: URL) {
        let context = PersistenceController.shared.context
        do {
            _ = fileURL.startAccessingSecurityScopedResource()
            defer { fileURL.stopAccessingSecurityScopedResource() }
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let importData = try decoder.decode([BoilerHouseData].self, from: jsonData)

            // Очистка старых объектов
            let oldSavedLocations = try context.fetch(SavedLocation.fetchRequest()) as! [SavedLocation]
            for obj in oldSavedLocations { context.delete(obj) }
            let oldBoilerHouses = try context.fetch(BoilerHouse.fetchRequest()) as! [BoilerHouse]
            for obj in oldBoilerHouses { context.delete(obj) }

            // Добавление новых объектов
            for bhData in importData {
                let bh = BoilerHouse(context: context)
                bh.name = bhData.name
                bh.latitude = bhData.latitude
                bh.longitude = bhData.longitude

                for slData in bhData.savedLocations {
                    let sl = SavedLocation(context: context)
                    sl.name = slData.name
                    sl.latitude = slData.latitude
                    sl.longitude = slData.longitude
                    sl.floors = Int32(slData.floors ?? 0)
                    sl.yearBuilt = Int32(slData.yearBuilt ?? 0)
                    sl.rooms = Int32(slData.rooms ?? 0)
                    sl.accounts = Int32(slData.accounts ?? 0)
                    sl.totalArea = slData.totalArea ?? 0
                    sl.managementCompany = slData.managementCompany
                    sl.boilerHouse = bh
                }
            }
            try context.save()
            loadItems()
            reloadAnnotations()
            showAlert(title: "Импорт завершён", message: "Загружено котельных: \(importData.count)")
        } catch {
            print("Ошибка импорта: \(error)")
            showAlert(title: "Ошибка импорта", message: error.localizedDescription)
        }
    }

    // --- Универсальный alert ---
    override func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
