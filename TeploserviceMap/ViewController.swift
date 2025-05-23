//
//  ViewController.swift
//  TeploserviceMap
//
//  Created by Shamil Aglarov on 23.05.2025.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {

    private let mapView = MKMapView()
    private let tableView = UITableView()
    private var isTableViewHidden = false
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private var mapViewHeightConstraint: NSLayoutConstraint?
    private var tableViewTopConstraint: NSLayoutConstraint?

    private var savedPoints: [SavedLocation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        mapView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        loadPoints()
        addSavedPointsToMap()

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecognizer)
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

    private func addPoint(name: String, latitude: Double, longitude: Double) {
        let context = PersistenceController.shared.context
        let newPoint = SavedLocation(context: context)
        newPoint.name = name
        newPoint.latitude = latitude
        newPoint.longitude = longitude
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

    @objc private func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: mapView)
            let coord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let alert = UIAlertController(title: "Новая точка", message: "Введите название точки", preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Название" }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                let nameInput = alert.textFields?.first?.text ?? ""
                let pointName = nameInput.isEmpty ? "Точка \(self.savedPoints.count + 1)" : nameInput
                self.addPoint(name: pointName, latitude: coord.latitude, longitude: coord.longitude)
                self.addSavedPointsToMap()
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)
        }
    }

    @objc private func addPointByCoordinates() {
        let alert = UIAlertController(title: "Добавить точку", message: "Введите координаты и название", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addTextField { $0.placeholder = "Широта (Latitude)" }
        alert.addTextField { $0.placeholder = "Долгота (Longitude)" }
        alert.addAction(UIAlertAction(title: "Добавить", style: .default, handler: { _ in
            guard let fields = alert.textFields,
                  let name = fields[0].text,
                  let lat = Double(fields[1].text ?? ""),
                  let lon = Double(fields[2].text ?? "") else {
                return
            }
            self.addPoint(name: name, latitude: lat, longitude: lon)
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

