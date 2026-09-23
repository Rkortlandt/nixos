;; Capture QML Object definitions and explicitly assign them a "Class" metadata kind
((ui_object_definition
   type_name: (identifier) @name) @symbol
 (#set! "kind" "Class"))
