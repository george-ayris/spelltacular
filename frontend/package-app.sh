rm -rf dist
mkdir dist
lein cljsbuild once min
cp resources/public/index.html dist
cp -r resources/public/css dist/css
cp -r resources/public/js/external dist/js/external

