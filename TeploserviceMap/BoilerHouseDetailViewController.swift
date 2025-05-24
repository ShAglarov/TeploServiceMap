//
//  HousesViewController.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 23.05.2025.
//

import UIKit
import MapKit
import CoreData

class BoilerHouseDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate {

    private let mapView = MKMapView()
    private let tableView = UITableView()
    private var boilerHouse: BoilerHouse
    private var savedPoints: [SavedLocation] = []

    private var tableViewHeightConstraint: NSLayoutConstraint?
    private var mapViewHeightConstraint: NSLayoutConstraint?
    private var tableViewTopConstraint: NSLayoutConstraint?
    private var isTableViewHidden = false

    // --- Floating меню ---
    private let floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 21
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 6
        button.alpha = 0.4
        return button
    }()

    private let mapTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "map.fill"), for: .normal)
        button.tintColor = .label
        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Инициализация с котельной
    init(boilerHouse: BoilerHouse) {
        self.boilerHouse = boilerHouse
        super.init(nibName: nil, bundle: nil)
        self.title = boilerHouse.name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
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

        // Tap для показа/скрытия списка домов
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tapRecognizer)

        setupFloatingMenu()
    }

    // MARK: - UI Setup
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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HouseCell")
        tableView.tableFooterView = UIView()

        // Плавающая кнопка
        view.addSubview(floatingButton)
        NSLayoutConstraint.activate([
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            floatingButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -24),
            floatingButton.widthAnchor.constraint(equalToConstant: 44),
            floatingButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Кнопка смены типа карты
        view.addSubview(mapTypeButton)
        NSLayoutConstraint.activate([
            mapTypeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 18),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 44),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        mapTypeButton.addTarget(self, action: #selector(showMapTypeMenu), for: .touchUpInside)

        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)
        tableViewHeightConstraint?.isActive = true

        // Центр на котельную
        let center = CLLocationCoordinate2D(latitude: boilerHouse.latitude, longitude: boilerHouse.longitude)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 3000, longitudinalMeters: 3000)
        mapView.setRegion(region, animated: false)
    }

    private func setupFloatingMenu() {
        floatingButton.showsMenuAsPrimaryAction = true
        floatingButton.menu = UIMenu(title: "", children: [
            UIAction(title: "Добавить дом", image: UIImage(systemName: "plus")) { [weak self] _ in
                self?.addHouseByCoordinates()
            },
            UIAction(title: "Импорт", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                // Импорт
            },
            UIAction(title: "Экспорт", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                // Экспорт
            },
            UIAction(title: "Удалить все", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                // Удалить все
            }
        ])
    }

    // MARK: - Загрузка и добавление домов

    private func loadPoints() {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        request.predicate = NSPredicate(format: "boilerHouse == %@", boilerHouse)
        do {
            savedPoints = try PersistenceController.shared.context.fetch(request)
            tableView.reloadData()
            addSavedPointsToMap()
        } catch {
            print("Ошибка загрузки домов котельной: \(error)")
        }
    }

    private func addHouse(
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
        newHouse.boilerHouse = boilerHouse // Привязка к котельной

        do {
            try context.save()
            loadPoints()
        } catch {
            print("Ошибка сохранения дома: \(error)")
        }
    }

    private func addSavedPointsToMap() {
        mapView.removeAnnotations(mapView.annotations)
        for point in savedPoints {
            let annotation = MKPointAnnotation()
            annotation.title = point.name
            annotation.coordinate = point.coordinate
            mapView.addAnnotation(annotation)
        }
        if !savedPoints.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: false)
        }
    }

    // MARK: - Добавление дома по кнопке
    @objc private func addHouseByCoordinates() {
        let alert = UIAlertController(title: "Добавить дом", message: "Введите характеристики дома", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addTextField { $0.placeholder = "Широта (Latitude)" }
        alert.addTextField { $0.placeholder = "Долгота (Longitude)" }
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
            self.addHouse(
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
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Добавление дома по долгому нажатию на карту
    @objc private func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
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
                self.addHouse(
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
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        }
    }

    // MARK: - Изменение режима карты
    @objc private func showMapTypeMenu() {
        let alert = UIAlertController(title: "Тип карты", message: nil, preferredStyle: .actionSheet)
        let types: [(String, MKMapType)] = [
            ("Стандарт", .standard),
            ("Спутник", .satellite),
            ("Гибрид", .hybrid)
        ]
        for (title, type) in types {
            let action = UIAlertAction(title: title, style: .default) { _ in
                self.mapView.mapType = type
            }
            if mapView.mapType == type {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = mapTypeButton.frame
        }
        present(alert, animated: true)
    }

    // MARK: - Показать/скрыть список
    @objc private func toggleListVisibility() {
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

    // Tap по карте
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        toggleListVisibility()
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedPoints.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HouseCell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "HouseCell")
        let point = savedPoints[indexPath.row]
        cell.textLabel?.text = point.name
        cell.detailTextLabel?.text = String(format: "Lat: %.4f, Lon: %.4f", point.latitude, point.longitude)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let point = savedPoints[indexPath.row]
        let region = MKCoordinateRegion(center: point.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0010, longitudeDelta: 0.0010))
        mapView.setRegion(region, animated: true)

        if let annotation = mapView.annotations.first(where: { ann in
            ann.coordinate.latitude == point.latitude && ann.coordinate.longitude == point.longitude
        }) {
            mapView.selectAnnotation(annotation, animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // Удаление дома свайпом
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = PersistenceController.shared.context
            let toDelete = savedPoints[indexPath.row]
            context.delete(toDelete)
            do {
                try context.save()
                loadPoints()
            } catch {
                print("Ошибка удаления дома: \(error)")
            }
        }
    }

    // Свайп: "Редактировать" и "Удалить"
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal, title: "Редакт.") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let point = self.savedPoints[indexPath.row]
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
                    self.loadPoints()
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
            let toDelete = self.savedPoints[indexPath.row]
            context.delete(toDelete)
            do {
                try context.save()
                self.loadPoints()
            } catch {
                print("Ошибка удаления дома: \(error)")
            }
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [delete, edit])
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKOverlayRenderer(overlay: overlay)
    }

    // MARK: - Долгое нажатие по таблице (можно сделать просмотр подробной информации)
    @objc private func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              gesture.state == .began else { return }

        let house = savedPoints[indexPath.row]
        let alert = UIAlertController(title: house.name, message: "Lat: \(house.latitude)\nLon: \(house.longitude)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}
