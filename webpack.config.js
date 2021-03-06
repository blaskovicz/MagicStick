const path = require("path");
const CleanWebpackPlugin = require("clean-webpack-plugin");
const webpack = require("webpack");
const webpackEnv = process.env.WEBPACK_ENV || "development";
module.exports = {
  entry: path.resolve(__dirname, "frontend", "app.js"),
  mode: webpackEnv,
  output: {
    path: path.resolve(__dirname, "public"),
    filename: "app.js"
  },
  // optimization: {
  //   splitChunks: {
  //     chunks: "all"
  //   }
  // },
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery"
    }),
    // new MiniCssExtractPlugin({
    //   filename: "[name].css"
    // }),
    new CleanWebpackPlugin(["public"], { exclude: ["img"], verbose: false }),
    // existing plugins go here
    new webpack.SourceMapDevToolPlugin({
      filename: null, // if no value is provided the sourcemap is inlined
      test: /\.(js)($|\?)/i // process .js files only
    })
  ],
  devtool: webpackEnv === "development" ? "eval" : "source-map",
  module: {
    rules: [
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
      }
    ]
  }
};
