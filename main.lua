-- tiny bootstrap: Fennel is authoritative source in src/*.fnl
package.path = package.path .. ";./src/?.lua;./vendor/share/lua/5.5/?.lua;./?.lua"
require("src.main")
