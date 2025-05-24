//
//  BaseMapListViewController.swift
//  TeploserviceMap
//
//  Created by Murad Tataev on 24.05.2025.
//

import UIKit
import MapKit
import CoreData

// MARK: - Базовый класс для любого экрана "Карта + список"
class BaseMapListViewController<Item: NSManagedObject>: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

    // --- Публичные свойства для дочерних классов ---
    let mapView = MKMapView()
    let tableView = UITableView()

    let floatingButton: UIButton = {
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
    let mapTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "map.fill"), for: .normal)
        // Яркая, но не броская иконка (голубой)
        button.tintColor = UIColor.systemBlue.withAlphaComponent(0.62)
        // Легкий прозрачный фон с голубым
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
        // Яркая иконка (зелёный)
        button.tintColor = UIColor.systemGreen.withAlphaComponent(0.62)
        // Лёгкий прозрачный фон с зеленоватым оттенком
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
    
    // Менеджер локации
       private let locationManager = CLLocationManager()

    // --- MARK: - Жизненный цикл ---
    override func viewDidLoad() {
        super.viewDidLoad()
        // Показываем текущее местоположение пользователя на карте
        mapView.showsUserLocation = true

        // Запрашиваем разрешение на использование геолокации
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        view.backgroundColor = .systemBackground
        setupUI()
        setupFloatingMenu()
        mapView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self

        // Tap для скрытия/отображения таблицы
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tapRecognizer)

        // Долгое нажатие по таблице (можно расширять в дочерних)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTableLongPress(_:)))
        tableView.addGestureRecognizer(longPress)

        // Долгое нажатие по карте (для добавления точки, реализуется в дочернем)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecognizer)
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
            floatingButton.widthAnchor.constraint(equalToConstant: 44),
            floatingButton.heightAnchor.constraint(equalToConstant: 44)
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

    // Вспомогательный метод — приблизить к пользователю
    func focusMapOnUserLocation(animated: Bool = true) {
        let userCoord = mapView.userLocation.coordinate
        if CLLocationCoordinate2DIsValid(userCoord) {
            let region = MKCoordinateRegion(center: userCoord, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
            mapView.setRegion(region, animated: animated)
        }
    }

//    // Автофокус после получения локации — только при первом появлении
//    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
//        focusMapOnUserLocation()
//    }

    // --- MARK: - Floating Menu (переопределять в дочерних) ---
    func setupFloatingMenu() {
        floatingButton.showsMenuAsPrimaryAction = true
        floatingButton.menu = UIMenu(title: "", children: [
            UIAction(title: "Добавить", image: UIImage(systemName: "plus")) { [weak self] _ in
                self?.showAddItemAlert()
            }
            // Можно добавить импорт/экспорт в дочерних
        ])
    }

    // --- MARK: - Смена режима карты ---
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

    // --- MARK: - Тап на карту ---
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        toggleListVisibility()
    }

    // --- MARK: - Долгое нажатие по карте (реализуется в дочерних) ---
    @objc func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Пустая реализация — дочерние классы реализуют свою логику
    }

    // --- MARK: - UITableViewDataSource (переопределять в дочерних) ---
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BaseCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "BaseCell")
        let cornerRadius: CGFloat = 22

        // Цвет “трубы” (можно подогнать под любую тему)
        let pipeColor = UIColor.systemGray6.withAlphaComponent(0.86)
        let pipeBorderColor = UIColor.systemGray4.withAlphaComponent(0.14)

        // Фон трубы
        let pipeView = UIView(frame: cell.bounds)
        pipeView.backgroundColor = pipeColor
        pipeView.layer.cornerRadius = cornerRadius
        pipeView.layer.masksToBounds = false
        pipeView.layer.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
        pipeView.layer.shadowOpacity = 0.6
        pipeView.layer.shadowOffset = CGSize(width: 0, height: 2)
        pipeView.layer.shadowRadius = 8

        // Лёгкие "швы" (имитируем разрез трубы между ячейками)
        let border = UIView(frame: CGRect(x: 0, y: pipeView.frame.height-1, width: pipeView.frame.width, height: 2))
        border.backgroundColor = pipeBorderColor
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        pipeView.addSubview(border)

        cell.backgroundView = pipeView

        // Контент — как обычно, но выравниваем чуть правее/левее для ощущения "внутри трубы"
        cell.textLabel?.text = "Title"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cell.textLabel?.textColor = UIColor.label
        cell.textLabel?.frame.origin.x += 16
        cell.detailTextLabel?.text = "Subtitle"
        cell.detailTextLabel?.textColor = UIColor.secondaryLabel
        cell.detailTextLabel?.frame.origin.x += 16

        // Убираем стандартный фон и разделители
        cell.backgroundColor = .clear
        tableView.separatorStyle = .none

        // Selected BG — делаем прозрачным, чтобы не мешал
        let selView = UIView()
        selView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        selView.layer.cornerRadius = cornerRadius
        cell.selectedBackgroundView = selView

        return cell
    }

    // --- MARK: - UITableViewDelegate (переопределять в дочерних) ---
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        focusMapOnItem(item)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - TableView: долгий тап (универсально)
    @objc func handleTableLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              gesture.state == .began else { return }
        let item = items[indexPath.row]
        handleLongPressOnItem(item)
    }

    // --- MARK: - MKMapViewDelegate (можно расширять в дочерних) ---
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKOverlayRenderer(overlay: overlay)
    }

    // --- MARK: - Методы для работы с данными (реализуются в дочерних) ---
    func loadItems() {
        // Переопредели для загрузки объектов (BoilerHouse или SavedLocation)
    }

    func showAddItemAlert() {
        // Переопредели для показа алерта добавления
    }

    // --- MARK: - Для swipe (переопределять в дочерних) ---
    func configureEditAlert(for item: Item, completion: @escaping () -> Void) -> UIAlertController {
        fatalError("configureEditAlert(for:completion:) must be overridden in subclass")
    }
    func handleDelete(item: Item, completion: @escaping () -> Void) {
        fatalError("handleDelete(item:completion:) must be overridden in subclass")
    }

    // --- MARK: - Заглушка для аннотаций (чтобы не было ошибок) ---
    func reloadAnnotations() {
        // Переопредели в дочернем, чтобы добавить свои аннотации на карту
    }

    // MARK: - TableView: выделение на карте по строке (универсально)
    func focusMapOnItem(_ item: Item) {
        // Заглушка — реализовать в дочернем, если у Item нет lat/lon
    }

    // Переопредели в наследнике — например, переход к другому экрану
    func handleLongPressOnItem(_ item: Item) {
        // В базовом классе — пусто или показать UIAlert, если универсально
    }

    func tableStyle() {
        // --- Стилизация таблицы ---
            tableView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.42) // Прозрачный фон
            tableView.separatorStyle = .none // Без стандартных разделителей

            // Если нужен эффект blur за таблицей (по желанию):
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = tableView.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            tableView.backgroundView = blurView
    }

    // --- MARK: - Универсальный swipe для редактирования и удаления ---
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
}
