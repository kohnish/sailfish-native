cmake_minimum_required(VERSION 3.19)
project(untitled CXX)

find_package (Qt5 COMPONENTS Core Network Qml Gui Quick REQUIRED)

if(CMAKE_CROSSCOMPILING)
    set_target_properties(Qt5::moc PROPERTIES
        IMPORTED_LOCATION "$ENV{HOME}/opt/qt5/5.6.3/gcc_64/bin/moc"
    )
    set_target_properties(Qt5::rcc PROPERTIES
        IMPORTED_LOCATION "$ENV{HOME}/opt/qt5/5.6.3/gcc_64/bin/rcc"
    )
endif()

include(FindPkgConfig)
pkg_search_module(SAILFISH sailfishapp REQUIRED)

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

add_executable(untitled src/untitled.cpp)
target_compile_definitions(untitled PRIVATE
    $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)
target_include_directories(untitled PRIVATE
    $<BUILD_INTERFACE:
    ${SAILFISH_INCLUDE_DIRS}
>)
target_link_libraries(untitled
    Qt5::Quick
    ${SAILFISH_LDFLAGS}
)

install(TARGETS untitled
    RUNTIME DESTINATION bin
)
install(DIRECTORY qml
    DESTINATION share/untitled
)
install(DIRECTORY translations
    DESTINATION share/untitled
    FILES_MATCHING PATTERN "*.qm"
)
install(FILES untitled.desktop
    DESTINATION share/applications
)
install(FILES icons/86x86/untitled.png
    DESTINATION share/icons/hicolor/86x86/apps
)
install(FILES icons/108x108/untitled.png
    DESTINATION share/icons/hicolor/108x108/apps
)
install(FILES icons/128x128/untitled.png
    DESTINATION share/icons/hicolor/128x128/apps
)
install(FILES icons/172x172/untitled.png
    DESTINATION share/icons/hicolor/172x172/apps
)

# Get the other files reachable from the project tree in Qt Creator
FILE(GLOB TsFiles "translations/*.ts")
add_custom_target(distfiles
    SOURCES
        untitled.desktop
        qml/untitled.qml
        qml/cover/CoverPage.qml
        qml/pages/FirstPage.qml
        qml/pages/SecondPage.qml
        rpm/untitled.changes.in
        rpm/untitled.changes.run.in
        rpm/untitled.spec
        rpm/untitled.yaml
        ${TsFiles})

# Tell Qt Creator where the application executable(s) would be located on the
# device.
#
# It is not necessary to list other deployables than executables (runtime
# targets) here. The deployment process of Sailfish OS projects is opaque to
# Qt Creator and the information contained in QtCreatorDeployment.txt is only
# used to locate the executable associated with the active run configuration
# on the device in order to run it.
#
# Search the Qt Creator Manual to learn about the QtCreatorDeployment.txt file
# format.
file(WRITE "${CMAKE_BINARY_DIR}/QtCreatorDeployment.txt"
    "${CMAKE_INSTALL_PREFIX}
${CMAKE_BINARY_DIR}/untitled:bin
")
