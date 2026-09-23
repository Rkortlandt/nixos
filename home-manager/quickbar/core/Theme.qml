pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Normal style (aesthetic black)
    property color normalBg: "#000000"
    property color normalHoverBg: "#1a1a1a"
    property color normalPressedBg: "#2a2a2a"
    property color normalText: "#ffffff"
    property color normalBorder: "#333333"

    // Primary style
    property color primaryBg: "#0f5880"
    property color primaryHoverBg: "#146896"
    property color primaryPressedBg: "#0a4463"
    property color primaryText: "#ffffff"
    property color primaryBorder: "#1e79ad"

    // Secondary style
    property color secondaryBg: "#172a7d"
    property color secondaryHoverBg: "#1e3599"
    property color secondaryPressedBg: "#111f5e"
    property color secondaryText: "#ffffff"
    property color secondaryBorder: "#2742b8"

    // Accent style
    property color accentBg: "#0ea16f"
    property color accentHoverBg: "#10b981"
    property color accentPressedBg: "#059669"
    property color accentText: "#ffffff"
    property color accentBorder: "#34d399"

    // Workspace indicators (derived from Primary & Accent)
    property color workspaceInactive: root.primaryBg
    property color workspaceActive: root.accentBg

    // Gradient style (global & adaptable)
    property color gradientStart: "#3b82f6"
    property color gradientEnd: "#8b5cf6"
    property color gradientText: "#ffffff"
    property color gradientBorder: "#60a5fa"

    // Global defaults
    property string fontFamily: "Inter"
    property int fontSize: 12
    property bool fontBold: true
    property int defaultHeight: 26
    property int defaultIconSize: 23
}
