//
//  HousesViewController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 23.05.2025.
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
        let request = SavedLocation.fetchRequest() 
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
            annotation.coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            mapView.addAnnotation(annotation)
        }
        if !items.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: false)
        }
    }

    // MARK: - Floating Menu — современный UX
    override func setupFloatingMenu() {
        floatingButton.showsMenuAsPrimaryAction = true
        floatingButton.menu = UIMenu(title: "", children: [
            UIAction(title: "Экспорт в json", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.exportAllBoilerHousesToJSONnew()
            },
            UIAction(title: "Импорт json", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                guard let self = self else { return }
                let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
                picker.delegate = self
                picker.allowsMultipleSelection = false
                picker.modalPresentationStyle = .formSheet
                self.present(picker, animated: true)
            }
        ])
    }
    
    override func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        importAllBoilerHousesFromJSONew(url: fileURL)
    }

    // MARK: - Добавить дом — современный способ
    func showAddItemScreen(withCoordinates coord: CLLocationCoordinate2D? = nil) {
        let context = PersistenceController.shared.context
        let newLocation = SavedLocation(context: context)
        newLocation.boilerHouse = boilerHouse
        if let coord = coord {
            newLocation.latitude = coord.latitude
            newLocation.longitude = coord.longitude
        }
        let vc = EditSavedLocationViewController(savedLocation: newLocation, isNew: true)
        vc.onSave = { [weak self] in
            self?.loadItems()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    override func exportToCSV() {
        super.exportToCSV()
    }

    override func exportAllBoilerHousesToOriginalJSON() {
        super.exportAllBoilerHousesToOriginalJSON()
    }

    // MARK: - Редактировать дом
    override func configureEditAlert(for item: SavedLocation, completion: @escaping () -> Void) -> UIAlertController {
        // Вместо алерта пушим экран редактирования
        let vc = EditSavedLocationViewController(savedLocation: item, isNew: false)
        vc.onSave = { [weak self] in
            self?.loadItems()
            completion()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
        // Возвращаем "пустой" алерт — он не используется, но требует реализации по сигнатуре
        return UIAlertController()
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
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let point = items[indexPath.row]
        cell.textLabel?.text = point.name
        cell.detailTextLabel?.text = String(format: "Lat: %.4f, Lon: %.4f", point.latitude, point.longitude)
        cell.accessoryType = .disclosureIndicator
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
        let detailVC = SavedLocationDetailViewController(savedLocation: item)
        self.navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Долгое нажатие по карте — добавить дом
    override func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: mapView)
            let coord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            self.showAddItemScreen(withCoordinates: coord)
        }
    }
}
