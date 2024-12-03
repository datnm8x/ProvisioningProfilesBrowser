import SwiftUI
import QuickLook

struct ContentView: View {
    @EnvironmentObject var profilesManager: ProvisioningProfilesManager
    @State private var selectedProfile: ProvisioningProfileModel.ID?
    
    var body: some View {
        VSplitView {
            ProfilesList(data: $profilesManager.visibleProfiles, selection: $selectedProfile)
            
            if let selectedProfile = selectedProfile,
               let profile = profilesManager.visibleProfiles.first(where: { $0.id == selectedProfile }) {
                ProvisioningPreview(profile: profile)
//                QuickLookPreview(url: profile.url)
                    .frame(width: NSApplication.contentViewBounds.width, height: NSApplication.contentViewBounds.height/2)
            } else {
                Color(.clear).frame(height: 0)
            }
        }
        .onAppear(perform: profilesManager.reload)
        .frame(minWidth: 1400, minHeight: 900)
        .alert(isPresented: $profilesManager.error.isNotNil) {
            Alert(
                title: Text("Error"),
                message: Text(profilesManager.error!.localizedDescription),
                dismissButton: Alert.Button.default(Text("OK"))
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension NSApplication {
    static var contentViewBounds: NSSize {
        NSSize(width: shared.keyWindow?.contentView?.bounds.width ?? 0, height: shared.keyWindow?.contentView?.bounds.height ?? 0)
    }
}
