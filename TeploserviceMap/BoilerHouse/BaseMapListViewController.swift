//
//  BaseMapListViewController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 24.05.2025.
//

import UIKit
import MapKit
import CoreData
import UniformTypeIdentifiers

// MARK: - Протокол для поддержки экспорта/импорта (опционально для универсальности)
protocol ExportablePoint: Codable {
    var name: String { get }
    var latitude: Double { get }
    var longitude: Double { get }
    var yearBuilt: Int? { get }
    var totalArea: Double? { get }
    var floors: Int? { get }
    var rooms: Int? { get }
    var accounts: Int? { get }
    var managementCompany: String? { get }
}

class BaseMapListViewController<Item: NSManagedObject>: UIViewController,
                                                        UITableViewDataSource,
                                                        UITableViewDelegate,
                                                        MKMapViewDelegate,
                                                        CLLocationManagerDelegate,
                                                        UIDocumentPickerDelegate {

    // --- Публичные свойства ---
    let mapView = MKMapView()
    let tableView = UITableView()

    let floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.setImage(UIImage(systemName: "pc"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 30
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 6
        button.alpha = 0.4
        return button
    }()
    let mapTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "map.fill"), for: .normal)
        button.tintColor = UIColor.systemBlue.withAlphaComponent(0.62)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.16)
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.systemBlue.withAlphaComponent(0.22).cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        button.alpha = 0.85
        return button
    }()
    let locateMeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.tintColor = UIColor.systemGreen.withAlphaComponent(0.62)
        button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.14)
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.systemGreen.withAlphaComponent(0.16).cgColor
        button.layer.shadowOpacity = 0.22
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        button.alpha = 0.85
        return button
    }()

    // --- Приватные свойства ---
    var items: [Item] = []
    var isTableViewHidden = false
    var tableViewHeightConstraint: NSLayoutConstraint?
    var mapViewHeightConstraint: NSLayoutConstraint?
    var tableViewTopConstraint: NSLayoutConstraint?
    private let locationManager = CLLocationManager()

    // Путь к файлу points.json в папке Documents
    private var jsonFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("points.json")
    }


    // --- MARK: - Жизненный цикл ---
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        view.backgroundColor = .systemBackground
        setupUI()
        setupFloatingMenu()
        mapView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tapRecognizer)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTableLongPress(_:)))
        tableView.addGestureRecognizer(longPress)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecognizer)

        tableStyle()
        loadItems()
        reloadAnnotations()
    }

    // --- MARK: - UI Setup ---
    func setupUI() {
        view.addSubview(mapView)
        view.addSubview(tableView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        mapViewHeightConstraint = mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: mapView.bottomAnchor)
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapViewHeightConstraint!,
            tableViewTopConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableViewHeightConstraint!
        ])

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BaseCell")
        tableView.tableFooterView = UIView()

        view.addSubview(floatingButton)
        NSLayoutConstraint.activate([
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            floatingButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -24),
            floatingButton.widthAnchor.constraint(equalToConstant: 60),
            floatingButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        view.addSubview(mapTypeButton)
        NSLayoutConstraint.activate([
            mapTypeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 18),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 44),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        mapTypeButton.addTarget(self, action: #selector(showMapTypeMenu), for: .touchUpInside)
        mapTypeButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        mapTypeButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchDragExit, .touchCancel])

        view.addSubview(locateMeButton)
        NSLayoutConstraint.activate([
            locateMeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            locateMeButton.bottomAnchor.constraint(equalTo: mapTypeButton.topAnchor, constant: -16),
            locateMeButton.widthAnchor.constraint(equalToConstant: 44),
            locateMeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        locateMeButton.addTarget(self, action: #selector(focusMapOnUserLocationButtonTapped), for: .touchUpInside)
        locateMeButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        locateMeButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchDragExit, .touchCancel])

        tableStyle()
    }

    @objc func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15) {
            sender.alpha = 0.6
            sender.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }
    }
    @objc func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.18) {
            sender.alpha = 0.85
            sender.transform = .identity
        }
    }

    // Кнопка "Найти меня"
    @objc func focusMapOnUserLocationButtonTapped() {
        focusMapOnUserLocation(animated: true)
    }
    func focusMapOnUserLocation(animated: Bool = true) {
        let userCoord = mapView.userLocation.coordinate
        if CLLocationCoordinate2DIsValid(userCoord) {
            let region = MKCoordinateRegion(center: userCoord, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
            mapView.setRegion(region, animated: animated)
        }
    }

    // --- MARK: - Floating Menu ---
    func setupFloatingMenu() {
        floatingButton.showsMenuAsPrimaryAction = true
        floatingButton.menu = UIMenu(title: "", children: [
            UIAction(title: "Экспортировать", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.exportItemsToJSON()
            },
            UIAction(title: "Импортировать", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                self?.importItemsFromJSON()
            },
            UIAction(title: "Загрузить из файла", image: UIImage(systemName: "doc")) { [weak self] _ in
                self?.importFromFileTapped()
            }
        ])
    }

    // --- MARK: - Экспорт/Импорт: заглушки (реализуй в наследнике для специфики) ---
    func exportItemsToJSON() {
        let exportArray: [ExportedPoint] = items.compactMap { item in
            var name: String = ""
            var latitude: Double = 0
            var longitude: Double = 0
            var yearBuilt: Int? = nil
            var totalArea: Double? = nil
            var floors: Int? = nil
            var rooms: Int? = nil
            var accounts: Int? = nil
            var managementCompany: String? = nil

            if let val = item.value(forKey: "name") as? String { name = val }
            if let val = item.value(forKey: "latitude") as? Double { latitude = val }
            if let val = item.value(forKey: "longitude") as? Double { longitude = val }
            if let val = item.entity.attributesByName["yearBuilt"], let valRaw = item.value(forKey: "yearBuilt") {
                yearBuilt = (valRaw as? Int) ?? (valRaw as? Int32).map { Int($0) }
            }
            if let _ = item.entity.attributesByName["totalArea"] {
                totalArea = item.value(forKey: "totalArea") as? Double
            }
            if let _ = item.entity.attributesByName["floors"] {
                floors = (item.value(forKey: "floors") as? Int) ?? (item.value(forKey: "floors") as? Int32).map { Int($0) }
            }
            if let _ = item.entity.attributesByName["rooms"] {
                rooms = (item.value(forKey: "rooms") as? Int) ?? (item.value(forKey: "rooms") as? Int32).map { Int($0) }
            }
            if let _ = item.entity.attributesByName["accounts"] {
                accounts = (item.value(forKey: "accounts") as? Int) ?? (item.value(forKey: "accounts") as? Int32).map { Int($0) }
            }
            if let _ = item.entity.attributesByName["managementCompany"] {
                managementCompany = item.value(forKey: "managementCompany") as? String
            }

            return ExportedPoint(
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
        }
        do {
            let data = try JSONEncoder().encode(exportArray)
            try data.write(to: jsonFileURL)
            let activityVC = UIActivityViewController(activityItems: [jsonFileURL], applicationActivities: nil)
            present(activityVC, animated: true)
        } catch {
            showAlert(title: "Ошибка экспорта", message: error.localizedDescription)
        }
    }

    func importItemsFromJSON() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: jsonFileURL.path) {
            showAlert(title: "Файл не найден", message: "Экспортируйте объекты перед импортом или скопируйте points.json в приложение через Files/AirDrop.")
            return
        }
        do {
            let data = try Data(contentsOf: jsonFileURL) // <-- исправлено здесь
            let imported = try JSONDecoder().decode([ExportedPoint].self, from: data)
            let context = PersistenceController.shared.context
            for object in items {
                context.delete(object)
            }
            for e in imported {
                let newObject = NSEntityDescription.insertNewObject(forEntityName: String(describing: Item.self), into: context)
                newObject.setValue(e.name, forKey: "name")
                newObject.setValue(e.latitude, forKey: "latitude")
                newObject.setValue(e.longitude, forKey: "longitude")
                newObject.setValue(e.yearBuilt ?? 0, forKey: "yearBuilt")
                newObject.setValue(e.totalArea ?? 0, forKey: "totalArea")
                newObject.setValue(e.floors ?? 0, forKey: "floors")
                newObject.setValue(e.rooms ?? 0, forKey: "rooms")
                newObject.setValue(e.accounts ?? 0, forKey: "accounts")
                newObject.setValue(e.managementCompany, forKey: "managementCompany")
            }
            try context.save()
            loadItems()
            reloadAnnotations()
            showAlert(title: "Импорт завершён", message: "Загружено объектов: \(imported.count)")
        } catch {
            showAlert(title: "Ошибка импорта JSON", message: error.localizedDescription)
        }
    }

    // --- MARK: - Импорт через DocumentPicker ---
    @objc private func importFromFileTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = docsURL.appendingPathComponent("points.json")
        var fileToRead = selectedURL

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
                    showAlert(title: "Ошибка копирования", message: error.localizedDescription)
                    return
                }
            }
        }
        do {
            let data = try Data(contentsOf: fileToRead)
            let imported = try JSONDecoder().decode([ExportedPoint].self, from: data) // <-- исправлено здесь
            let context = PersistenceController.shared.context
            for object in items { context.delete(object) }
            for e in imported {
                let newObject = NSEntityDescription.insertNewObject(forEntityName: String(describing: Item.self), into: context)
                newObject.setValue(e.name, forKey: "name")
                newObject.setValue(e.latitude, forKey: "latitude")
                newObject.setValue(e.longitude, forKey: "longitude")
                newObject.setValue(e.yearBuilt ?? 0, forKey: "yearBuilt")
                newObject.setValue(e.totalArea ?? 0, forKey: "totalArea")
                newObject.setValue(e.floors ?? 0, forKey: "floors")
                newObject.setValue(e.rooms ?? 0, forKey: "rooms")
                newObject.setValue(e.accounts ?? 0, forKey: "accounts")
                newObject.setValue(e.managementCompany, forKey: "managementCompany")
            }
            try context.save()
            loadItems()
            reloadAnnotations()
            showAlert(title: "Импорт завершён", message: "Загружено объектов: \(imported.count)")
        } catch {
            showAlert(title: "Ошибка импорта JSON", message: error.localizedDescription)
        }
    }


    // --- MARK: - TableView стиль ---
    func tableStyle() {
        tableView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.42)
        tableView.separatorStyle = .none
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = tableView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundView = blurView
    }

    // --- MARK: - UITableViewDataSource ---
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BaseCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "BaseCell")
        // Универсально — наследник сам кастует к нужному типу и выводит нужные данные
        let cornerRadius: CGFloat = 22
        let pipeColor = UIColor.systemGray6.withAlphaComponent(0.86)
        let pipeBorderColor = UIColor.systemGray4.withAlphaComponent(0.14)
        let pipeView = UIView(frame: cell.bounds)
        pipeView.backgroundColor = pipeColor
        pipeView.layer.cornerRadius = cornerRadius
        pipeView.layer.masksToBounds = false
        pipeView.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        pipeView.layer.shadowOpacity = 0.6
        pipeView.layer.shadowOffset = CGSize(width: 0, height: 2)
        pipeView.layer.shadowRadius = 8

        let border = UIView(frame: CGRect(x: 0, y: pipeView.frame.height-1, width: pipeView.frame.width, height: 2))
        border.backgroundColor = pipeBorderColor
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        pipeView.addSubview(border)
        cell.backgroundView = pipeView

        // Демо-значения (наследник делает свой кастинг и вывод)
        cell.textLabel?.text = "Title"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cell.textLabel?.textColor = UIColor.label
        cell.detailTextLabel?.text = "Subtitle"
        cell.detailTextLabel?.textColor = UIColor.secondaryLabel
        cell.backgroundColor = .clear
        tableView.separatorStyle = .none

        let selView = UIView()
        selView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        selView.layer.cornerRadius = cornerRadius
        cell.selectedBackgroundView = selView

        return cell
    }

    // --- MARK: - UITableViewDelegate ---
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        focusMapOnItem(item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    @objc func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point), gesture.state == .began else { return }
        let item = items[indexPath.row]
        handleLongPressOnItem(item)
    }

    // --- MARK: - MKMapViewDelegate ---
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKOverlayRenderer(overlay: overlay)
    }

    // --- MARK: - Методы для работы с данными (реализуются в дочерних) ---
    func loadItems() {
        // Переопредели для загрузки объектов
    }
    func showAddItemAlert() {
        // Переопредели для показа алерта добавления
    }
    func reloadAnnotations() {
        // Переопредели в дочернем
    }

    // --- MARK: - Карта ---
    @objc func showMapTypeMenu() {
        let alert = UIAlertController(title: "Тип карты", message: nil, preferredStyle: .actionSheet)
        let types: [(String, MKMapType)] = [
            ("Стандарт", .standard),
            ("Спутник", .satellite),
            ("Гибрид", .hybrid)
        ]
        for (title, type) in types {
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.mapView.mapType = type
            }
            if mapView.mapType == type {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = mapTypeButton.frame
        }
        present(alert, animated: true)
    }

    // --- MARK: - Скрыть/Показать таблицу ---
    @objc func toggleListVisibility() {
        isTableViewHidden.toggle()
        if isTableViewHidden {
            mapViewHeightConstraint?.isActive = false
            mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            tableView.isHidden = true
        } else {
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = false
            mapViewHeightConstraint?.isActive = true
            tableView.isHidden = false
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        toggleListVisibility()
    }
    @objc func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Реализовать в дочерних
    }

    // --- MARK: - Заглушки для расширения ---
    func configureEditAlert(for item: Item, completion: @escaping () -> Void) -> UIAlertController {
        fatalError("configureEditAlert(for:completion:) must be overridden in subclass")
    }
    func handleDelete(item: Item, completion: @escaping () -> Void) {
        fatalError("handleDelete(item:completion:) must be overridden in subclass")
    }
    func focusMapOnItem(_ item: Item) {
        // Переопредели для поддержки выбора точки на карте
    }
    func handleLongPressOnItem(_ item: Item) {
        // Переопредели для действий по долгому тапу
    }

    // --- MARK: - Swipe actions ---
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]
        let edit = UIContextualAction(style: .normal, title: "Редакт.") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let alert = self.configureEditAlert(for: item) {
                self.loadItems()
                self.reloadAnnotations()
            }
            self.present(alert, animated: true)
            completionHandler(true)
        }
        edit.backgroundColor = UIColor.orange

        let delete = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            self.handleDelete(item: item) {
                self.loadItems()
                self.reloadAnnotations()
            }
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }

    // --- MARK: - Alerts ---
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
