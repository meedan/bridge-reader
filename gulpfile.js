var gulp = require('gulp');
var browserSync = require('browser-sync');
var reload = browserSync.reload;
var sass = require('gulp-sass');
var scssFiles = "app/assets/sass/**/*.scss";
var cssCompileDir = "public/stylesheets";
var bowerDir = "vendor/assets/bower_components";

// Browsersync configuration
// 
// Proxy to the default rails port.
// Warning: The rails server must be booted to this port before you can run this app.
var serverConfig = {
  proxy: "localhost:3000"
};

// A Browsersync task 
// 
// Starting the server.
gulp.task('browser-sync', function () {
  browserSync(serverConfig);
});

// A Sass task
// 
// Run this when any SCSS files change & BrowserSync should auto-update browsers (without a full refresh).
gulp.task('sass', function () {
  return gulp.src(scssFiles)
    .pipe(sass({
      includePaths: [bowerDir],
      errLogToConsole: true
    }))
    .pipe(gulp.dest(cssCompileDir))
    .pipe(reload({
      stream: true
    }));
});

// Another Browsersync task  
// 
// We "manually" do a "full refresh" of  the browser instead of stream-injection (used in the Sass task)
// This is e.g. for when you edit the html
// via http://www.browsersync.io/docs/gulp/
// 
gulp.task('bs-reload', function () {
  browserSync.reload();
});

// Default task to be run with `gulp` on CLI
gulp.task('default', ['sass', 'browser-sync'], function () {
  gulp.watch(scssFiles, ['sass']);
  // gulp.watch("public/**/*.html", ['bs-reload']);
});