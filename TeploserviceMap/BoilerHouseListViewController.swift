//
//  File.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 23.05.2025.
//

import UIKit
import MapKit
import CoreData

class BoilerHouseListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate {

    private let mapView = MKMapView()
    private let tableView = UITableView()
    private var isTableViewHidden = false
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private var mapViewHeightConstraint: NSLayoutConstraint?
    private var tableViewTopConstraint: NSLayoutConstraint?

    private var boilerHouses: [BoilerHouse] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Котельные"
        view.backgroundColor = .systemBackground
        setupUI()
        mapView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        loadBoilerHouses()
        addBoilerHousesToMap()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTableLongPress(_:)))
        tableView.addGestureRecognizer(longPress)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecognizer)
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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BoilerCell")
        
        tableView.tableFooterView = UIView()

        let addButton = UIButton(type: .system)
        addButton.setTitle("Добавить котельную", for: .normal)
        addButton.addTarget(self, action: #selector(addBoilerHouseTapped), for: .touchUpInside)
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

        let center = CLLocationCoordinate2D(latitude: 42.9778, longitude: 47.5147)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 9000, longitudinalMeters: 9000)
        mapView.setRegion(region, animated: false)
    }

    // MARK: - Работа с котельными

    private func loadBoilerHouses() {
        let request: NSFetchRequest<BoilerHouse> = BoilerHouse.fetchRequest()
        do {
            boilerHouses = try PersistenceController.shared.context.fetch(request)
            tableView.reloadData()
            addBoilerHousesToMap()
        } catch {
            print("Ошибка загрузки котельных: \(error)")
        }
    }

    private func addBoilerHouse(
        name: String,
        latitude: Double,
        longitude: Double
    ) {
        let context = PersistenceController.shared.context
        let newBoiler = BoilerHouse(context: context)
        newBoiler.name = name
        newBoiler.latitude = latitude
        newBoiler.longitude = longitude

        do {
            try context.save()
            self.loadBoilerHouses()
        } catch {
            print("Ошибка сохранения котельной: \(error)")
        }
    }

    private func addBoilerHousesToMap() {
        mapView.removeAnnotations(mapView.annotations)
        for boiler in boilerHouses {
            guard boiler.latitude != 0, boiler.longitude != 0 else { continue }
            let annotation = MKPointAnnotation()
            annotation.title = boiler.name ?? "Без названия"
            annotation.coordinate = CLLocationCoordinate2D(latitude: boiler.latitude, longitude: boiler.longitude)
            mapView.addAnnotation(annotation)
        }
        if !boilerHouses.isEmpty {
            mapView.showAnnotations(mapView.annotations, animated: false)
        }
    }

    // MARK: - Добавление по долгому нажатию на карту

    @objc private func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: mapView)
            let coord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let alert = UIAlertController(title: "Новая котельная", message: "Введите название котельной", preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Название" }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                let name = alert.textFields?.first?.text ?? ""
                self.addBoilerHouse(
                    name: name,
                    latitude: coord.latitude,
                    longitude: coord.longitude
                )
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        }
    }

    // MARK: - Добавление котельной по кнопке

    @objc private func addBoilerHouseTapped() {
        let alert = UIAlertController(title: "Добавить котельную", message: "Введите название и координаты", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addTextField { $0.placeholder = "Широта (Latitude)" }
        alert.addTextField { $0.placeholder = "Долгота (Longitude)" }
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
            let fields = alert.textFields!
            let name = fields[0].text ?? ""
            let latitude = Double(fields[1].text ?? "") ?? 0
            let longitude = Double(fields[2].text ?? "") ?? 0
            self.addBoilerHouse(
                name: name,
                latitude: latitude,
                longitude: longitude
            )
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
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

    // MARK: - Долгое нажатие по таблице

    @objc private func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              gesture.state == .began else { return }

        let selectedBoiler = boilerHouses[indexPath.row]
        let alert = UIAlertController(
            title: selectedBoiler.name ?? "Котельная",
            message: "Здесь можно реализовать быстрое редактирование или переход к списку домов.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
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
        let newTitle = isTableViewHidden ? "Показать список" : "Скрыть список"
        (view.subviews.first(where: { $0 is UIButton && ($0 as! UIButton).currentTitle?.contains("список") == true }) as? UIButton)?.setTitle(newTitle, for: .normal)
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return boilerHouses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoilerCell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "BoilerCell")
        let boiler = boilerHouses[indexPath.row]
        cell.textLabel?.text = boiler.name ?? "Без названия"
        cell.detailTextLabel?.text = String(format: "Lat: %.4f, Lon: %.4f", boiler.latitude, boiler.longitude)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let boiler = boilerHouses[indexPath.row]
        let coord = CLLocationCoordinate2D(latitude: boiler.latitude, longitude: boiler.longitude)
        let region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.0010, longitudeDelta: 0.0010))
        mapView.setRegion(region, animated: true)

        // Выделяем аннотацию на карте
        if let annotation = mapView.annotations.first(where: { ann in
            ann.coordinate.latitude == boiler.latitude && ann.coordinate.longitude == boiler.longitude
        }) {
            mapView.selectAnnotation(annotation, animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // Удаление котельных свайпом
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = PersistenceController.shared.context
            let toDelete = boilerHouses[indexPath.row]
            context.delete(toDelete)
            do {
                try context.save()
                loadBoilerHouses()
            } catch {
                print("Ошибка удаления котельной: \(error)")
            }
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Кнопка редактирования
        let edit = UIContextualAction(style: .normal, title: "Редакт.") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let boiler = self.boilerHouses[indexPath.row]
            let alert = UIAlertController(title: "Редактировать котельную", message: "Измените название или координаты", preferredStyle: .alert)
            alert.addTextField { $0.text = boiler.name }
            alert.addTextField { $0.text = boiler.latitude == 0 ? "" : "\(boiler.latitude)" }
            alert.addTextField { $0.text = boiler.longitude == 0 ? "" : "\(boiler.longitude)" }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                let fields = alert.textFields!
                boiler.name = fields[0].text ?? ""
                boiler.latitude = Double(fields[1].text ?? "") ?? 0
                boiler.longitude = Double(fields[2].text ?? "") ?? 0
                do {
                    try PersistenceController.shared.context.save()
                    self.loadBoilerHouses()
                } catch {
                    print("Ошибка сохранения: \(error)")
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alert, animated: true)
            completionHandler(true)
        }
        edit.backgroundColor = .orange

        // Кнопка удаления
        let delete = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let context = PersistenceController.shared.context
            let toDelete = self.boilerHouses[indexPath.row]
            context.delete(toDelete)
            do {
                try context.save()
                self.loadBoilerHouses()
            } catch {
                print("Ошибка удаления котельной: \(error)")
            }
            completionHandler(true)
        }

        // Порядок в массиве ― справа налево: [удалить, редактировать]
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }

    // MARK: - MKMapViewDelegate (аннотация — круг если надо)
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        circleRenderer.fillColor = UIColor.red.withAlphaComponent(0.3)
        circleRenderer.strokeColor = .red
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
}
