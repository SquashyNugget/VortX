import SwiftUI

/// tvOS presentation primitives. Data, navigation destinations, and playback remain with the
/// existing screen owners; these views do not create a second catalogue or history store.
enum TVCinema {
    static let ink = Color.white
    static let secondaryInk = Color.white.opacity(0.76)
    static let quietInk = Color.white.opacity(0.58)
    static let panel = Color(red: 0.055, green: 0.062, blue: 0.075)
    static let edge = Color.white.opacity(0.15)
    static let pageInset: CGFloat = Theme.Space.screenEdge
}

struct TVCinemaScreenHeader: View {
    let title: String
    var eyebrow: String? = nil
    var subtitle: String? = nil
    var centered = false

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 10) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(Theme.Typography.eyebrow)
                    .tracking(2.2)
                    .foregroundStyle(TVCinema.quietInk)
            }
            Text(title)
                .font(Theme.Typography.screenTitle)
                .tracking(-1.2)
                .foregroundStyle(TVCinema.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Typography.label)
                    .foregroundStyle(TVCinema.secondaryInk)
                    .lineLimit(2)
            }
        }
        .multilineTextAlignment(centered ? .center : .leading)
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}

/// High-contrast actions for the Home feature. A custom style gives the remote a visible focus
/// state without introducing another focus coordinator or intercepting Menu/Back.
struct TVCinemaActionStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        TVCinemaActionContent(configuration: configuration, prominent: prominent)
    }
}

private struct TVCinemaActionContent: View {
    let configuration: ButtonStyleConfiguration
    let prominent: Bool
    @Environment(\.isFocused) private var focused
    @ReducedMotion private var reduceMotion

    var body: some View {
        configuration.label
            .font(Theme.Typography.label.weight(.semibold))
            .foregroundStyle(prominent ? Color.black : TVCinema.ink)
            .padding(.horizontal, 28)
            .frame(minHeight: 66)
            .background {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(prominent ? Color.white : TVCinema.panel.opacity(focused ? 0.96 : 0.82))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(prominent ? (focused ? Color.black.opacity(0.8) : .clear)
                                            : Color.white.opacity(focused ? 0.85 : 0.28),
                                  lineWidth: focused ? 2 : 1)
            }
            .scaleEffect(focused && !reduceMotion ? 1.035 : (configuration.isPressed ? 0.98 : 1))
            .shadow(color: .black.opacity(focused ? 0.58 : 0.30), radius: focused ? 18 : 10, y: 8)
            .animation(reduceMotion ? nil : Theme.Motion.focus, value: focused)
            .animation(reduceMotion ? nil : Theme.Motion.state, value: configuration.isPressed)
    }
}

/// Focused artwork already belongs to `FocusedItemModel`. The buttons open the real detail page:
/// movies expose the existing Watch/source pipeline, while series open their episode browser.
/// No direct URL, synthetic source, or new progress state is constructed here.
struct TVCinemaHomeActions: View {
    @ObservedObject var model: FocusedItemModel
    var restrictedIDs: Set<String> = []

    var body: some View {
        Group {
            if let hero = model.hero, !hero.id.isEmpty, !restrictedIDs.contains(hero.id) {
                HStack(spacing: 14) {
                    if hero.type == "movie" {
                        NavigationLink {
                            DetailView(type: hero.type, id: hero.id)
                        } label: {
                            Label("Choose a source", systemImage: "play.fill")
                        }
                        .buttonStyle(TVCinemaActionStyle(prominent: true))
                        .accessibilityHint("Opens VortX's playback and source selection")
                    } else if hero.type == "series" {
                        NavigationLink {
                            DetailView(type: hero.type, id: hero.id)
                        } label: {
                            Label("Browse episodes", systemImage: "play.rectangle.on.rectangle")
                        }
                        .buttonStyle(TVCinemaActionStyle(prominent: true))
                    }
                    if hero.type != "movie" && hero.type != "series" {
                        NavigationLink {
                            DetailView(type: hero.type, id: hero.id)
                        } label: {
                            Label("Details", systemImage: "info.circle")
                        }
                        .buttonStyle(TVCinemaActionStyle())
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, TVCinema.pageInset)
                .padding(.vertical, 12)
            }
        }
    }
}
