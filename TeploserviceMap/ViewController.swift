//
//  ViewController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 23.05.2025.
//

import UIKit
import MapKit
import CoreData
import UniformTypeIdentifiers

class ViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {

    private let mapView = MKMapView()
    private let tableView = UITableView()
    private var isTableViewHidden = false
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private var mapViewHeightConstraint: NSLayoutConstraint?
    private var tableViewTopConstraint: NSLayoutConstraint?

    private var savedPoints: [SavedLocation] = []

    // Получаем путь к файлу points.json в папке Documents
    private var jsonFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("points.json")
    }


    private func exportPointsToJSON() {
        let exportArray = savedPoints.map {
            ExportedPoint(
                name: $0.name,
                latitude: $0.latitude,
                longitude: $0.longitude,
                yearBuilt: $0.yearBuilt == 0 ? nil : Int($0.yearBuilt),
                totalArea: $0.totalArea == 0 ? nil : $0.totalArea,
                floors: $0.floors == 0 ? nil : Int($0.floors),
                rooms: $0.rooms == 0 ? nil : Int($0.rooms),
                accounts: $0.accounts == 0 ? nil : Int($0.accounts),
                managementCompany: $0.managementCompany
            )
        }
        do {
            let data = try JSONEncoder().encode(exportArray)
            try data.write(to: jsonFileURL)
            let activityVC = UIActivityViewController(activityItems: [jsonFileURL], applicationActivities: nil)
            present(activityVC, animated: true)
        } catch {
            print("Ошибка экспорта JSON:", error)
        }
    }

    private func importPointsFromJSON() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: jsonFileURL.path) {
            let alert = UIAlertController(title: "Файл не найден", message: "Экспортируйте точки перед импортом, либо скопируйте points.json в приложение через Files/AirDrop.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        do {
            let data = try Data(contentsOf: jsonFileURL)
            let imported = try JSONDecoder().decode([ExportedPoint].self, from: data)
            let context = PersistenceController.shared.context
            for point in savedPoints {
                context.delete(point)
            }
            for e in imported {
                let newPoint = SavedLocation(context: context)
                newPoint.name = e.name
                newPoint.latitude = e.latitude
                newPoint.longitude = e.longitude
                newPoint.yearBuilt = Int32(e.yearBuilt ?? 0)
                newPoint.totalArea = e.totalArea ?? 0
                newPoint.floors = Int32(e.floors ?? 0)
                newPoint.rooms = Int32(e.rooms ?? 0)
                newPoint.accounts = Int32(e.accounts ?? 0)
                newPoint.managementCompany = e.managementCompany
            }
            try context.save()
            loadPoints()
            addSavedPointsToMap()
            print("Импортировано точек:", imported.count)
        } catch {
            print("Ошибка импорта JSON:", error)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        mapView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        loadPoints()
        addSavedPointsToMap()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTableLongPress(_:)))
        tableView.addGestureRecognizer(longPress)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecognizer)

    }

    @objc private func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              gesture.state == .began else { return }

        let selectedPoint = savedPoints[indexPath.row]
        presentEditDetailsAlert(for: selectedPoint)
    }

    @objc private func mapTypeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: mapView.mapType = .standard
        case 1: mapView.mapType = .satellite
        case 2: mapView.mapType = .hybrid
        default: break
        }
    }

    @objc private func toggleListVisibility() {
        isTableViewHidden.toggle()

        if isTableViewHidden {
            // Отключаем constraint высоты карты и тянем карту на весь экран
            mapViewHeightConstraint?.isActive = false
            mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            tableView.isHidden = true
        } else {
            // Возвращаем исходные constraints (карта 60%, таблица 40%)
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = false
            mapViewHeightConstraint?.isActive = true
            tableView.isHidden = false
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }

        let newTitle = isTableViewHidden ? "Показать список" : "Скрыть список"
        (view.subviews.first(where: { $0 is UIButton && ($0 as! UIButton).currentTitle?.contains("список") == true }) as? UIButton)?.setTitle(newTitle, for: .normal)
    }

    private func setupUI() {
        view.addSubview(mapView)
        view.addSubview(tableView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        mapViewHeightConstraint = mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: mapView.bottomAnchor)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapViewHeightConstraint!,
            tableViewTopConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PointCell")
        tableView.tableFooterView = UIView()

        let addButton = UIButton(type: .system)
        addButton.setTitle("Добавить точку", for: .normal)
        addButton.addTarget(self, action: #selector(addPointByCoordinates), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])

        let editButton = UIButton(type: .system)
        editButton.setTitle("Редактировать", for: .normal)
        editButton.addTarget(self, action: #selector(toggleEditMode), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editButton)
        NSLayoutConstraint.activate([
            editButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            editButton.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8)
        ])

        let mapTypeControl = UISegmentedControl(items: ["Стандарт", "Спутник", "Гибрид"])
        mapTypeControl.selectedSegmentIndex = 0
        mapTypeControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapTypeControl)
        NSLayoutConstraint.activate([
            mapTypeControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            mapTypeControl.heightAnchor.constraint(equalToConstant: 30),
            mapTypeControl.widthAnchor.constraint(equalToConstant: 260),
            mapTypeControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        mapTypeControl.addTarget(self, action: #selector(mapTypeChanged(_:)), for: .valueChanged)

        let toggleListButton = UIButton(type: .system)
        toggleListButton.setTitle("Показать список", for: .normal)
        toggleListButton.translatesAutoresizingMaskIntoConstraints = false
        toggleListButton.backgroundColor = .white
        toggleListButton.layer.cornerRadius = 8
        toggleListButton.layer.shadowOpacity = 0.2
        toggleListButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        toggleListButton.addTarget(self, action: #selector(toggleListVisibility), for: .touchUpInside)
        view.addSubview(toggleListButton)
        NSLayoutConstraint.activate([
            toggleListButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            toggleListButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toggleListButton.widthAnchor.constraint(equalToConstant: 140),
            toggleListButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)
        tableViewHeightConstraint?.isActive = true

        let center = CLLocationCoordinate2D(latitude: 42.9778, longitude: 47.5147)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 9000, longitudinalMeters: 9000)
        mapView.setRegion(region, animated: false)

        

        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Экспорт точек", for: .normal)
        exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exportButton)

        let importButton = UIButton(type: .system)
        importButton.setTitle("Импорт точек", for: .normal)
        importButton.addTarget(self, action: #selector(importButtonTapped), for: .touchUpInside)
        importButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(importButton)

        // Пример Constraints (подбери, чтобы красиво расположить)
        NSLayoutConstraint.activate([
            exportButton.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 8),
            exportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            importButton.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 8),
            importButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])

        let importFromFileButton = UIButton(type: .system)
        importFromFileButton.setTitle("Загрузить из файла", for: .normal)
        importFromFileButton.translatesAutoresizingMaskIntoConstraints = false
        importFromFileButton.backgroundColor = .white
        importFromFileButton.layer.cornerRadius = 8
        importFromFileButton.layer.shadowOpacity = 0.2
        importFromFileButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        importFromFileButton.addTarget(self, action: #selector(importFromFileTapped), for: .touchUpInside)
        view.addSubview(importFromFileButton)

        NSLayoutConstraint.activate([
            importFromFileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            importFromFileButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80), // чтобы не пересекалось с другими кнопками
            importFromFileButton.widthAnchor.constraint(equalToConstant: 170),
            importFromFileButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }


    @objc private func importFromFileTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    @objc private func importFromJSON() {
        importPointsFromJSON()
    }

    @objc private func exportButtonTapped() {
        exportPointsToJSON()
    }

    @objc private func importButtonTapped() {
        importPointsFromJSON()
    }

    @objc private func toggleEditMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }

    private func loadPoints() {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        do {
            savedPoints = try PersistenceController.shared.context.fetch(request)
            tableView.reloadData()
        } catch {
            print("Ошибка загрузки точек: \(error)")
        }
    }

    private func addPoint(
        name: String,
        latitude: Double,
        longitude: Double,
        yearBuilt: Int32 = 0,
        totalArea: Double = 0,
        floors: Int32 = 0,
        rooms: Int32 = 0,
        accounts: Int32 = 0,
        managementCompany: String = ""
    ) {
        let context = PersistenceController.shared.context
        let newPoint = SavedLocation(context: context)
        newPoint.name = name
        newPoint.latitude = latitude
        newPoint.longitude = longitude
        newPoint.yearBuilt = yearBuilt
        newPoint.totalArea = totalArea
        newPoint.floors = floors
        newPoint.rooms = rooms
        newPoint.accounts = accounts
        newPoint.managementCompany = managementCompany
        saveContext()
        loadPoints()
    }

    private func saveContext() {
        let context = PersistenceController.shared.context
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }

    private func addSavedPointsToMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        for point in savedPoints {
            let annotation = MKPointAnnotation()
            annotation.title = point.name
            annotation.coordinate = point.coordinate
            mapView.addAnnotation(annotation)

            let circleOverlay = MKCircle(center: point.coordinate, radius: 10)
            mapView.addOverlay(circleOverlay)
        }
        if !savedPoints.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: false)
        }
    }

    @objc func importJSONTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @objc private func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: mapView)
            let coord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let alert = UIAlertController(title: "Новая точка", message: "Введите данные", preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Название" }
            alert.addTextField { $0.placeholder = "Год постройки (например, 2003)" }
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
                self.addPoint(
                    name: name,
                    latitude: coord.latitude,
                    longitude: coord.longitude,
                    yearBuilt: yearBuilt,
                    totalArea: totalArea,
                    floors: floors,
                    rooms: rooms,
                    accounts: accounts,
                    managementCompany: managementCompany
                )
                self.addSavedPointsToMap()
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        }
    }

    @objc private func addPointByCoordinates() {
        let alert = UIAlertController(title: "Добавить точку", message: "Введите данные", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addTextField { $0.placeholder = "Широта (Latitude)" }
        alert.addTextField { $0.placeholder = "Долгота (Longitude)" }
        alert.addTextField { $0.placeholder = "Год постройки (например, 2003)" }
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
            self.addPoint(
                name: name,
                latitude: latitude,
                longitude: longitude,
                yearBuilt: yearBuilt,
                totalArea: totalArea,
                floors: floors,
                rooms: rooms,
                accounts: accounts,
                managementCompany: managementCompany
            )
            self.addSavedPointsToMap()
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedPoints.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PointCell", for: indexPath)
        let point = savedPoints[indexPath.row]
        cell.textLabel?.text = point.name
        cell.detailTextLabel?.text = String(format: "Lat: %.4f, Lon: %.4f", point.latitude, point.longitude)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let point = savedPoints[indexPath.row]
        let region = MKCoordinateRegion(center: point.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0010, longitudeDelta: 0.0010))
        mapView.setRegion(region, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let point = savedPoints[indexPath.row]
            if let annotation = mapView.annotations.first(where: {
                $0.coordinate.latitude == point.latitude && $0.coordinate.longitude == point.longitude
            }) {
                mapView.removeAnnotation(annotation)
            }
            if let overlay = mapView.overlays.first(where: { overlay in
                guard let circle = overlay as? MKCircle else { return false }
                return abs(circle.coordinate.latitude - point.latitude) < 1e-6 && abs(circle.coordinate.longitude - point.longitude) < 1e-6
            }) {
                mapView.removeOverlay(overlay)
            }
            PersistenceController.shared.context.delete(point)
            saveContext()
            loadPoints()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal, title: "Редакт.") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let point = self.savedPoints[indexPath.row]
            let alert = UIAlertController(title: "Редактировать точку", message: "Измените название точки", preferredStyle: .alert)
            alert.addTextField { $0.text = point.name }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
                point.name = newName
                self.saveContext()
                self.loadPoints()
                if let annotation = self.mapView.annotations.first(where: {
                    $0.coordinate.latitude == point.latitude && $0.coordinate.longitude == point.longitude
                }) as? MKPointAnnotation {
                    annotation.title = newName
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alert, animated: true)
            completionHandler(true)
        }
        edit.backgroundColor = .orange
        return UISwipeActionsConfiguration(actions: [edit])
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        if let index = savedPoints.firstIndex(where: { abs($0.latitude - circleOverlay.coordinate.latitude) < 1e-6 && abs($0.longitude - circleOverlay.coordinate.longitude) < 1e-6 }) {
            let color: UIColor = (index % 2 == 0) ? .red : .blue
            circleRenderer.fillColor = color.withAlphaComponent(0.3)
            circleRenderer.strokeColor = color
        } else {
            circleRenderer.fillColor = UIColor.red.withAlphaComponent(0.3)
            circleRenderer.strokeColor = .red
        }
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = docsURL.appendingPathComponent("points.json") // всегда сохраняем под одним именем

        var fileToRead = selectedURL

        // Проверяем, нужно ли копировать (если файл не в папке Documents)
        if selectedURL.deletingLastPathComponent() != docsURL {
            if selectedURL.startAccessingSecurityScopedResource() {
                defer { selectedURL.stopAccessingSecurityScopedResource() }
                do {
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.copyItem(at: selectedURL, to: destinationURL)
                    fileToRead = destinationURL
                } catch {
                    let alert = UIAlertController(title: "Ошибка копирования", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ок", style: .default))
                    present(alert, animated: true)
                    return
                }
            }
        } else {
            // Если файл уже в Documents — ничего не копируем
            fileToRead = selectedURL
        }

        // Теперь читаем данные из fileToRead
        do {
            let data = try Data(contentsOf: fileToRead)
            let imported = try JSONDecoder().decode([ExportedPoint].self, from: data)
            let context = PersistenceController.shared.context
            for point in savedPoints { context.delete(point) }
            for e in imported {
                let newPoint = SavedLocation(context: context)
                newPoint.name = e.name
                newPoint.latitude = e.latitude
                newPoint.longitude = e.longitude
                newPoint.yearBuilt = Int32(e.yearBuilt ?? 0)
                newPoint.totalArea = e.totalArea ?? 0
                newPoint.floors = Int32(e.floors ?? 0)
                newPoint.rooms = Int32(e.rooms ?? 0)
                newPoint.accounts = Int32(e.accounts ?? 0)
                newPoint.managementCompany = e.managementCompany
            }
            try context.save()
            loadPoints()
            addSavedPointsToMap()
            let alert = UIAlertController(title: "Импорт завершён", message: "Загружено точек: \(imported.count)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            present(alert, animated: true)
        } catch {
            let alert = UIAlertController(title: "Ошибка импорта JSON", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            present(alert, animated: true)
        }
    }

    func presentEditDetailsAlert(for point: SavedLocation) {
        let alert = UIAlertController(title: "Характеристики дома", message: "Введите/измените информацию", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Год постройки (например, 2003)"; $0.text = point.yearBuilt == 0 ? "" : "\(point.yearBuilt)" }
        alert.addTextField { $0.placeholder = "Общая площадь (кв.м.)"; $0.text = point.totalArea == 0 ? "" : "\(point.totalArea)" }
        alert.addTextField { $0.placeholder = "Этажей"; $0.text = point.floors == 0 ? "" : "\(point.floors)" }
        alert.addTextField { $0.placeholder = "Помещений"; $0.text = point.rooms == 0 ? "" : "\(point.rooms)" }
        alert.addTextField { $0.placeholder = "Лицевых счетов"; $0.text = point.accounts == 0 ? "" : "\(point.accounts)" }
        alert.addTextField { $0.placeholder = "Управляющая организация"; $0.text = point.managementCompany }

        alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
            let fields = alert.textFields!
            point.yearBuilt = Int32(fields[0].text ?? "") ?? 0
            point.totalArea = Double(fields[1].text ?? "") ?? 0
            point.floors = Int32(fields[2].text ?? "") ?? 0
            point.rooms = Int32(fields[3].text ?? "") ?? 0
            point.accounts = Int32(fields[4].text ?? "") ?? 0
            point.managementCompany = fields[5].text ?? ""
            self.saveContext()
            self.loadPoints()
            self.addSavedPointsToMap()
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}
