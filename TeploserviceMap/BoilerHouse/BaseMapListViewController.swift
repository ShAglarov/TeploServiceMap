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
import CoreXLSX

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

    // Отображение поисковой строки
    @objc func showSearchScreen() {
        let categoryVC = SearchCategoryViewController()
        categoryVC.onCategorySelected = { [weak categoryVC] category in
            let searchVC = AccountsSearchViewController(category: category)
            let nav = UINavigationController(rootViewController: searchVC)
            categoryVC?.present(nav, animated: true)
        }
        present(categoryVC, animated: true)
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
            UIAction(title: "Экспортировать ВСЕ", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.exportAllBoilerHousesToJSON()
            },
            UIAction(title: "Импортировать ВСЕ", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
                picker.delegate = self
                picker.allowsMultipleSelection = false
                picker.modalPresentationStyle = .formSheet
                self?.present(picker, animated: true)
            },
            UIAction(title: "Найти", image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
                print("Пункт найти выбран")
                self?.showSearchScreen()
            }
        ])
    }

    // --- MARK: - XOR "шифрование" для Data (замени на свой алгоритм если нужно) ---
    func customEncrypt(_ data: Data) -> Data {
        let key: UInt8 = 0xAA // ЛЮБОЙ ключ, лучше замени на свой
        return Data(data.map { $0 ^ key })
    }
    func customDecrypt(_ data: Data) -> Data {
        return customEncrypt(data) // тот же XOR для дешифровки
    }

    // MARK: - Экспорт "секьюрного Data-JSON"
    func exportAllBoilerHousesToJSON() {
        let context = PersistenceController.shared.context
        let fetchRequest: NSFetchRequest<BoilerHouse> = BoilerHouse.fetchRequest()
        do {
            let boilerHouses = try context.fetch(fetchRequest)
            let exportArray: [ExportedBoilerHouse] = boilerHouses.map { boiler in
                ExportedBoilerHouse(
                    name: boiler.name ?? "",
                    latitude: boiler.latitude,
                    longitude: boiler.longitude,
                    savedLocations: (boiler.savedLocations as? Set<SavedLocation>)?.map { location in
                        ExportedSavedLocation(
                            name: location.name ?? "",
                            latitude: location.latitude,
                            longitude: location.longitude,
                            floors: Int(location.floors),
                            yearBuilt: Int(location.yearBuilt),
                            rooms: Int(location.rooms),
                            accounts: (location.myAccounts as? Set<MyAccount>)?.map { acc in
                                ExportedAccount(
                                    accountNumber: acc.accountNumber ?? "",
                                    fio: acc.fio ?? "",
                                    area: acc.area,
                                    status: acc.status ?? "",
                                    openDate: acc.openDate,
                                    closeDate: acc.closeDate,
                                    phone: acc.phone ?? "",
                                    email: acc.email ?? "",
                                    address: acc.address ?? ""
                                )
                            } ?? [],
                            totalArea: location.totalArea,
                            managementCompany: location.managementCompany
                        )
                    } ?? []
                )
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(exportArray)
            let encryptedData = customEncrypt(jsonData)
            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent("boilerhouses.json")
            try encryptedData.write(to: tmpUrl)
            let activityVC = UIActivityViewController(activityItems: [tmpUrl], applicationActivities: nil)
            present(activityVC, animated: true)
        } catch {
            showAlert(title: "Ошибка экспорта", message: error.localizedDescription)
        }
    }

    // MARK: - Импорт "секьюрного Data-JSON"
    func importAllBoilerHousesFromJSON(url: URL) {
        let context = PersistenceController.shared.context
        do {
            var needsStop = false
            if url.startAccessingSecurityScopedResource() {
                needsStop = true
            }
            defer {
                if needsStop { url.stopAccessingSecurityScopedResource() }
            }
            // 1. Читаем бинарный Data
            let encryptedData = try Data(contentsOf: url)
            // 2. Декодируем
            let jsonData = customDecrypt(encryptedData)
            // 3. Теперь обычный декодер JSON
            let imported = try JSONDecoder().decode([ExportedBoilerHouse].self, from: jsonData)

            // Удаляем всё старое
            let oldAccounts = try context.fetch(MyAccount.fetchRequest()) as! [MyAccount]
            for obj in oldAccounts { context.delete(obj) }
            let oldSavedLocations = try context.fetch(SavedLocation.fetchRequest()) as! [SavedLocation]
            for obj in oldSavedLocations { context.delete(obj) }
            let oldBoilerHouses = try context.fetch(BoilerHouse.fetchRequest()) as! [BoilerHouse]
            for obj in oldBoilerHouses { context.delete(obj) }

            // Импорт новых данных
            for bhData in imported {
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
                    sl.totalArea = slData.totalArea ?? 0
                    sl.managementCompany = slData.managementCompany
                    sl.boilerHouse = bh

                    for acc in slData.accounts {
                        let newAcc = MyAccount(context: context)
                        newAcc.accountNumber = acc.accountNumber
                        newAcc.fio = acc.fio
                        newAcc.area = acc.area
                        newAcc.status = acc.status
                        newAcc.openDate = acc.openDate
                        newAcc.closeDate = acc.closeDate
                        newAcc.phone = acc.phone
                        newAcc.email = acc.email
                        newAcc.address = acc.address
                        newAcc.location = sl
                    }
                }
            }
            try context.save()
            loadItems()
            reloadAnnotations()
            showAlert(title: "Импорт завершён", message: "Загружено котельных: \(imported.count)")
        } catch {
            showAlert(title: "Ошибка импорта JSON", message: error.localizedDescription)
        }
    }

    // --- MARK: - Импорт через DocumentPicker ---
    @objc func importFromFileTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        importAllBoilerHousesFromJSON(url: fileURL)
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

    func exportToCSV() {
        let context = PersistenceController.shared.context
        let fetchRequest: NSFetchRequest<BoilerHouse> = BoilerHouse.fetchRequest()
        do {
            let boilerHouses = try context.fetch(fetchRequest)

            // Собираем строки для CSV
            var csv = "Котельная,Объект,Адрес,Управляющая компания,Год постройки,ЛС (accountNumber),ФИО,Статус,Площадь,Открыт,Закрыт,Телефон,Email\n"

            for boiler in boilerHouses {
                let boilerName = boiler.name ?? ""
                guard let locations = boiler.savedLocations as? Set<SavedLocation> else { continue }
                for loc in locations {
                    let objectName = loc.name ?? ""
                    let managementCompany = loc.managementCompany ?? ""
                    let yearBuilt = loc.yearBuilt != 0 ? "\(loc.yearBuilt)" : ""
                    guard let accounts = loc.myAccounts as? Set<MyAccount> else { continue }
                    for acc in accounts {
                        let row: [String] = [
                            boilerName,
                            objectName,
                            acc.address ?? "",
                            managementCompany,
                            yearBuilt,
                            acc.accountNumber ?? "",
                            acc.fio ?? "",
                            acc.status ?? "",
                            acc.area != 0 ? "\(acc.area)" : "",
                            acc.openDate?.description ?? "",
                            acc.closeDate?.description ?? "",
                            acc.phone ?? "",
                            acc.email ?? ""
                        ]
                        csv += row.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
                    }
                }
            }

            let data = csv.data(using: .utf8)!
            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent("export.csv")
            try data.write(to: tmpUrl)
            let activityVC = UIActivityViewController(activityItems: [tmpUrl], applicationActivities: nil)
            present(activityVC, animated: true)

        } catch {
            showAlert(title: "Ошибка экспорта в CSV", message: error.localizedDescription)
        }
    }

    func exportAllBoilerHousesToOriginalJSON() {
        let context = PersistenceController.shared.context
        let fetchRequest: NSFetchRequest<BoilerHouse> = BoilerHouse.fetchRequest()
        do {
            let boilerHouses = try context.fetch(fetchRequest)
            let exportArray: [ExportedBoilerHouse] = boilerHouses.map { boiler in
                ExportedBoilerHouse(
                    name: boiler.name ?? "",
                    latitude: boiler.latitude,
                    longitude: boiler.longitude,
                    savedLocations: (boiler.savedLocations as? Set<SavedLocation>)?.map { location in
                        ExportedSavedLocation(
                            name: location.name ?? "",
                            latitude: location.latitude,
                            longitude: location.longitude,
                            floors: Int(location.floors),
                            yearBuilt: Int(location.yearBuilt),
                            rooms: Int(location.rooms),
                            accounts: (location.myAccounts as? Set<MyAccount>)?.map { acc in
                                ExportedAccount(
                                    accountNumber: acc.accountNumber ?? "",
                                    fio: acc.fio ?? "",
                                    area: acc.area,
                                    status: acc.status ?? "",
                                    openDate: acc.openDate,
                                    closeDate: acc.closeDate,
                                    phone: acc.phone ?? "",
                                    email: acc.email ?? "",
                                    address: acc.address ?? ""
                                )
                            } ?? [],
                            totalArea: location.totalArea,
                            managementCompany: location.managementCompany
                        )
                    } ?? []
                )
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(exportArray)
            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent("boilerhouses.json")
            try data.write(to: tmpUrl)
            let activityVC = UIActivityViewController(activityItems: [tmpUrl], applicationActivities: nil)
            present(activityVC, animated: true)
        } catch {
            showAlert(title: "Ошибка экспорта", message: error.localizedDescription)
        }
    }
    
    func importAllBoilerHousesFromJSONew(url: URL) {
            var needsStop = false
            // Разрешаем временный доступ к файлу, выбранному через Document Picker
            if url.startAccessingSecurityScopedResource() {
                needsStop = true
            }
            defer {
                if needsStop { url.stopAccessingSecurityScopedResource() }
            }
            do {
                // 1. Чтение данных из файла
                let data = try Data(contentsOf: url)
                print("Считан файл: \(url.lastPathComponent), размер: \(data.count) байт")
                
                // 2. Для отладки: покажи содержимое файла
                if let str = String(data: data, encoding: .utf8) {
                    print("Содержимое файла:\n\(str)")
                }
                
                // 3. Пробуем декодировать массив ExportedBoilerHouse
                let decoder = JSONDecoder()
                let imported = try decoder.decode([ExportedBoilerHouse].self, from: data)
                print("Импортировано котельных: \(imported.count)")
                
                // 4. Логика сохранения данных в CoreData (пример)
                let context = PersistenceController.shared.context
                
                // Удаляем старые данные (если нужно)
                let oldAccounts = try context.fetch(MyAccount.fetchRequest()) as! [MyAccount]
                for obj in oldAccounts { context.delete(obj) }
                let oldSavedLocations = try context.fetch(SavedLocation.fetchRequest()) as! [SavedLocation]
                for obj in oldSavedLocations { context.delete(obj) }
                let oldBoilerHouses = try context.fetch(BoilerHouse.fetchRequest()) as! [BoilerHouse]
                for obj in oldBoilerHouses { context.delete(obj) }
                
                // Импорт новых данных
                for bhData in imported {
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
                        sl.totalArea = slData.totalArea ?? 0
                        sl.managementCompany = slData.managementCompany
                        sl.boilerHouse = bh
                        
                        for acc in slData.accounts {
                            let newAcc = MyAccount(context: context)
                            newAcc.accountNumber = acc.accountNumber
                            newAcc.fio = acc.fio
                            newAcc.area = acc.area
                            newAcc.status = acc.status
                            newAcc.openDate = acc.openDate
                            newAcc.closeDate = acc.closeDate
                            newAcc.phone = acc.phone
                            newAcc.email = acc.email
                            newAcc.address = acc.address
                            newAcc.location = sl
                        }
                    }
                }
                // 5. Сохраняем изменения в CoreData
                try context.save()
                // 6. Обновляем UI
                loadItems()
                reloadAnnotations()
                // 7. Уведомление об успехе
                showAlert(title: "Импорт завершён", message: "Загружено котельных: \(imported.count)")
            } catch {
                print("Ошибка импорта: \(error)")
                showAlert(title: "Ошибка импорта JSON", message: error.localizedDescription)
            }
        }
    
    func exportAllBoilerHousesToJSONnew() {
            let context = PersistenceController.shared.context
            let fetchRequest: NSFetchRequest<BoilerHouse> = BoilerHouse.fetchRequest()
            do {
                let boilerHouses = try context.fetch(fetchRequest)
                let exportArray: [ExportedBoilerHouse] = boilerHouses.map { boiler in
                    ExportedBoilerHouse(
                        name: boiler.name ?? "",
                        latitude: boiler.latitude,
                        longitude: boiler.longitude,
                        savedLocations: (boiler.savedLocations as? Set<SavedLocation>)?.map { location in
                            ExportedSavedLocation(
                                name: location.name ?? "",
                                latitude: location.latitude,
                                longitude: location.longitude,
                                floors: Int(location.floors),
                                yearBuilt: Int(location.yearBuilt),
                                rooms: Int(location.rooms),
                                accounts: (location.myAccounts as? Set<MyAccount>)?.map { acc in
                                    ExportedAccount(
                                        accountNumber: acc.accountNumber ?? "",
                                        fio: acc.fio ?? "",
                                        area: acc.area,
                                        status: acc.status ?? "",
                                        openDate: acc.openDate,
                                        closeDate: acc.closeDate,
                                        phone: acc.phone ?? "",
                                        email: acc.email ?? "",
                                        address: acc.address ?? ""
                                    )
                                } ?? [],
                                totalArea: location.totalArea,
                                managementCompany: location.managementCompany
                            )
                        } ?? []
                    )
                }
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(exportArray)
                let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent("boilerhouses.json")
                try jsonData.write(to: tmpUrl)
                let activityVC = UIActivityViewController(activityItems: [tmpUrl], applicationActivities: nil)
                present(activityVC, animated: true)
            } catch {
                showAlert(title: "Ошибка экспорта", message: error.localizedDescription)
            }
        }

}
