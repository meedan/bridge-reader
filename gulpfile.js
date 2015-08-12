var gulp = require('gulp');
var browserSync = require('browser-sync');
var prefix = require('gulp-autoprefixer');
var sass = require('gulp-sass');
var scssPath = "./app/assets/sass/";
var scssFiles = scssPath + "**/*.scss";
var cssCompileDir = "public/stylesheets";
var bowerDir = "vendor/assets/bower_components";

gulp.task('browser-sync', ['sass'], function () {
  browserSync({
    server: {
      proxy: 'localhost:3000',
      baseDir: 'public/'
    }
  });
});

gulp.task('sass', function () {
  return gulp.src([scssFiles])
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
    }))
});

gulp.task('watch', function () {
  gulp.watch(scssFiles, ['sass']);
});

gulp.task('default', ['browser-sync', 'watch']);