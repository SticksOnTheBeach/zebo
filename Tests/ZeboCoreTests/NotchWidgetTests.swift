import Foundation
import Testing

@testable import ZeboCore

@Suite("Widgets de la notch")
struct NotchWidgetTests {
    private func at(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: seconds)
    }

    @Test("Sans widget, rien à afficher")
    func noWidget() {
        #expect(NotchWidgetRotation.widget(among: [], every: 10, at: at(0)) == nil)
    }

    @Test("Un seul widget reste affiché")
    func singleWidgetStays() {
        #expect(NotchWidgetRotation.widget(among: [.date], every: 10, at: at(12_345)) == .date)
    }

    @Test("Plusieurs widgets se relaient à chaque intervalle, puis recommencent")
    func widgetsRotate() {
        let widgets: [NotchWidget] = [.clock, .commits, .language]
        let shown = [0, 9, 10, 25, 30].map { NotchWidgetRotation.widget(among: widgets, every: 10, at: at($0)) }
        #expect(shown == [.clock, .clock, .commits, .language, .clock])
    }

    @Test("Ajouter un widget garde l'ordre de la liste, peu importe l'ordre des clics")
    func widgetsKeepCatalogOrder() {
        var preferences = ZeboPreferences(name: "", notchWidgets: [])
        preferences.setWidget(.language, shown: true)
        preferences.setWidget(.clock, shown: true)
        preferences.setWidget(.commits, shown: true)
        #expect(preferences.notchWidgets == [.clock, .commits, .language])
        preferences.setWidget(.commits, shown: false)
        #expect(preferences.notchWidgets == [.clock, .language])
    }

    @Test("Le widget du langage ne s'affiche qu'avec un langage choisi")
    func languageNeedsAFavorite() {
        var preferences = ZeboPreferences(name: "", notchWidgets: [.clock, .language])
        #expect(preferences.displayableWidgets == [.clock])
        preferences.favoriteLanguage = .swift
        #expect(preferences.displayableWidgets == [.clock, .language])
    }
}
