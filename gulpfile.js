////
/// Meedan Gulp configuration 
/// [1] BrowserSync management w/ Rails proxy
/// [2] Sass compilation task w/ autoprefixer
/// [3] Watch task, refresh on all Sass edits
/// [4] Default task

var gulp = require('gulp');
var browserSync = require('browser-sync');
var prefix = require('gulp-autoprefixer');
var sass = require('gulp-sass');
var scssPath = "./app/assets/sass";
var scssFiles = scssPath + "/**/*.scss";
var cssCompileDir = "public/stylesheets";
var bowerDir = "vendor/assets/bower_components";

/// [1]
gulp.task('browser-sync', ['sass'], function () {
  browserSync({
    server: {
      baseDir: './public',
      proxy: "localhost:3000"
    }
  });
});

/// [2] 
gulp.task('sass', function () {
  return gulp.src(scssFiles)
    .pipe(sass({
      includePaths: [scssPath, bowerDir],
      onError: browserSync.notify
    }))
    .pipe(prefix(['last 15 versions', '> 1%'], {
      cascade: true
    }))
    .pipe(gulp.dest(cssCompileDir))
    .pipe(browserSync.reload({
      stream: true
    }));
});

/// [3] 
gulp.task('watch', function () {
  gulp.watch(scssFiles, ['sass']);
});

/// [4]
gulp.task('default', ['browser-sync', 'watch']);