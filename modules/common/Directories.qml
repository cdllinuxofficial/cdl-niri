pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import QtCore
import QtQuick
import Quickshell

Singleton {
    // XDG base dirs — explicit cdl-niri paths, no binary-name dependency
    readonly property string home:        StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property string config:      `${Directories.home}/.config/cdl-niri`
    readonly property string state:       `${Directories.home}/.local/state/cdl-niri`
    readonly property string cache:       `${Directories.home}/.cache/cdl-niri`
    readonly property string genericCache:`${Directories.home}/.cache`
    readonly property string documents:   StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
    readonly property string downloads:   StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    readonly property string pictures:    StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string music:       StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
    readonly property string videos:      StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]

    // Shell paths
    property string assetsPath:   Quickshell.shellPath("assets")
    property string scriptPath:   Quickshell.shellPath("scripts")

    // Media cache
    property string favicons:       FileUtils.trimFileProtocol(`${Directories.cache}/media/favicons`)
    property string coverArt:       FileUtils.trimFileProtocol(`${Directories.cache}/media/coverart`)
    property string tempImages:     "/tmp/cdl-niri/media/images"
    property string booruPreviews:  FileUtils.trimFileProtocol(`${Directories.cache}/media/boorus`)
    property string booruDownloads: FileUtils.trimFileProtocol(Directories.pictures + "/homework")
    property string booruDownloadsNsfw: FileUtils.trimFileProtocol(Directories.pictures + "/homework/🌶️")
    property string latexOutput:    FileUtils.trimFileProtocol(`${Directories.cache}/media/latex`)

    // Shell config
    property string shellConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/config.json`)

    // State
    property string todoPath:              FileUtils.trimFileProtocol(`${Directories.state}/user/todo.json`)
    property string notesPath:             FileUtils.trimFileProtocol(`${Directories.state}/user/notes.txt`)
    property string conflictCachePath:     FileUtils.trimFileProtocol(`${Directories.cache}/conflict-killer`)
    property string notificationsPath:     FileUtils.trimFileProtocol(`${Directories.cache}/notifications/notifications.json`)
    property string generatedMaterialThemePath:    FileUtils.trimFileProtocol(`${Directories.state}/user/generated/colors.json`)
    property string generatedWallpaperCategoryPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/wallpaper/category.txt`)
    property string generatedNiriColorsPath:       FileUtils.trimFileProtocol(`${Directories.state}/user/generated/niri-colors.kdl`)

    // Misc
    property string cliphistDecode:    FileUtils.trimFileProtocol("/tmp/cdl-niri/media/cliphist")
    property string screenshotTemp:    "/tmp/cdl-niri/media/screenshot"
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/switchwall.sh`)
    property string defaultAiPrompts:  Quickshell.shellPath("defaults/ai/prompts")
    property string userAiPrompts:     FileUtils.trimFileProtocol(`${Directories.config}/ai/prompts`)
    property string userActions:       FileUtils.trimFileProtocol(`${Directories.config}/actions`)
    property string aiChats:           FileUtils.trimFileProtocol(`${Directories.state}/user/ai/chats`)
    property string aiTranslationScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/gemini-translate.sh`)
    property string recordScriptPath:  FileUtils.trimFileProtocol(`${Directories.scriptPath}/videos/record.sh`)
    property string userAvatarPathAccountsService: FileUtils.trimFileProtocol(`/var/lib/AccountsService/icons/${SystemInfo.username}`)
    property string userAvatarPathRicersAndWeirdSystems:  FileUtils.trimFileProtocol(`${Directories.home}/.face`)
    property string userAvatarPathRicersAndWeirdSystems2: FileUtils.trimFileProtocol(`${Directories.home}/.face.icon`)

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", FileUtils.trimFileProtocol(Directories.config)])
        Quickshell.execDetached(["mkdir", "-p", favicons])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${coverArt}'; mkdir -p '${coverArt}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${booruPreviews}'; mkdir -p '${booruPreviews}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${latexOutput}'; mkdir -p '${latexOutput}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${cliphistDecode}'; mkdir -p '${cliphistDecode}'`])
        Quickshell.execDetached(["mkdir", "-p", aiChats])
        Quickshell.execDetached(["mkdir", "-p", userActions])
        Quickshell.execDetached(["rm", "-rf", tempImages])
    }
}
