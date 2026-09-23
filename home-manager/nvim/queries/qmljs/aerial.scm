;; Capture QML Object instances (e.g., ApplicationWindow {}, Rectangle {})
(ui_object_definition
  (ui_object_initializer) @name) @symbol

;; Optional: Capture custom properties defined inside the elements
(property_declaration
  (identifier) @name) @symbol

