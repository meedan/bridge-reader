var gulp = require('gulp');
var browserSync = require('browser-sync');
var sass = require('gulp-sass');
var scssFiles = "app/assets/sass/**/*.scss";
var cssCompileDir = "public/stylesheets";
var bowerDir = "vendor/assets/bower_components";

// // A Sass task
// // 
// // Run this when any SCSS files change & BrowserSync should auto-update browsers (without a full refresh).
// gulp.task('sass', function () {
//   return gulp.src(scssFiles)
//     .pipe(sass({
//       includePaths: [bowerDir],
//       errLogToConsole: true
//     }))
//     .pipe(gulp.dest(cssCompileDir))
//     .pipe(reload({
//       stream: true
//     }));
// });

// // Another Browsersync task  
// // 
// // We "manually" do a "full refresh" of  the browser instead of stream-injection (used in the Sass task)
// // This is e.g. for when you edit the html
// // via http://www.browsersync.io/docs/gulp/
// // 
// gulp.task('bs-reload', function () {
//   browserSync.reload();
// });

// // Default task to be run with `gulp` on CLI
// gulp.task('default', ['sass', 'browser-sync'], function () {
//   gulp.watch(scssFiles, ['sass']);
//   // gulp.watch("public/**/*.html", ['bs-reload']);
// });


/**
 * Wait for sass, then launch the Server
 */
gulp.task('browser-sync', ['sass'], function () {
  browserSync({
    server: {
      proxy: "localhost:3000"
    }
  });
});

gulp.task('sass', function () {
  return gulp.src(['sass/screen.scss', 'sass/screenshot.scss'])
    .pipe(sass({
      includePaths: ['app/assets/sass'],
      onError: browserSync.notify
    }))
    .pipe(prefix(['last 15 versions', '> 1%'], {
      cascade: true
    }))
    .pipe(gulp.dest('public/stylesheets'))
    .pipe(browserSync.reload({
      stream: true
    }))
});

/**
 * Watch scss files for changes & recompile
 */
gulp.task('watch', function () {
  gulp.watch('app/assets/sass/*.scss', ['sass']);
});

/**
 * Default task, running just `gulp` will compile the sass,
 * compile the jekyll site, launch BrowserSync & watch files.
 */
gulp.task('default', ['browser-sync', 'watch']);