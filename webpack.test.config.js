const path = require("path");
const webpack = require("webpack");
module.exports = {
  entry: path.resolve(__dirname, "frontend", "specs.js"),
  mode: "development",
  output: {
    path: path.resolve(__dirname, "public"),
    filename: "specs.js"
  },
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery"
    }),
    // existing plugins go here
    new webpack.SourceMapDevToolPlugin({
      filename: null, // if no value is provided the sourcemap is inlined
      test: /\.(js)($|\?)/i // process .js files only
    })
  ],
  devtool: "inline-source-map",
  module: {
    rules: [
      {
        test: /\.js$/,
        use: ["source-map-loader"],
        enforce: "pre"
      },
      {
        test: /\.html$/,
        use: {
          loader: "html-loader"
        }
      },
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: "babel-loader",
          options: {
            presets: ["@babel/preset-env"]
          }
        }
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"]
      },
      {
        test: /\.scss$/,
        use: [
          {
            loader: "style-loader"
          },
          {
            loader: "css-loader",
            options: {
              sourceMap: true
            }
          },
          {
            loader: "sass-loader",
            options: {
              sourceMap: true
            }
          }
        ]
      },
      {
        test: /\.(png|jpg|gif|svg|eot|ttf|woff|woff2)$/,
        loader: "url-loader",
        options: {
          limit: 10000
        }
      },
      {
        // delays coverage till after tests are run
        test: /\.js$/,
        exclude: /node_modules|\.spec\.js$/,
        use: {
          loader: "istanbul-instrumenter-loader",
          options: { esModules: true }
        },
        enforce: "post"
      }
    ]
  }
};
