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

        let addButton = UIButton(type: .system)
        addButton.setTitle("Добавить дом", for: .normal)
        addButton.addTarget(self, action: #selector(addHouseByCoordinates), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
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

        // Центр на котельную
        let center = CLLocationCoordinate2D(latitude: boilerHouse.latitude, longitude: boilerHouse.longitude)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 3000, longitudinalMeters: 3000)
        mapView.setRegion(region, animated: false)
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

    // MARK: - MKMapViewDelegate
    @objc private func mapTypeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: mapView.mapType = .standard
        case 1: mapView.mapType = .satellite
        case 2: mapView.mapType = .hybrid
        default: break
        }
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
        let newTitle = isTableViewHidden ? "Показать список" : "Скрыть список"
        (view.subviews.first(where: { $0 is UIButton && ($0 as! UIButton).currentTitle?.contains("список") == true }) as? UIButton)?.setTitle(newTitle, for: .normal)
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
