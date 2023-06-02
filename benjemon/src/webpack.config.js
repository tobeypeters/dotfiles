module.exports = {
    // Other webpack configuration options...

    module: {
      rules: [
        {
            // test: /\.(png|jpe?g|gif|svg|pdf)$/i,
            test: /\.(json)$/i,
            use: [
            {
              loader: 'file-loader',
              options: {
                emitFile: true, // Ensures file is emitted by the loader
                name: '[name].[ext]',
                outputPath: 'data', // Output directory for emitted files
                publicPath: '/data' // Public URL path for emitted files
              }
            }
          ]
        }
      ]
    }
  };
