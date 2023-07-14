const aws = require("aws-sdk");
const axios = require("axios");

const s3Client = new aws.S3({
  region: process.env.BUCKET_REGION,
  credentials: {
    accessKeyId: process.env.BUCKET_ACCESS_KEY,
    secretAccessKey: process.env.BUCKET_SECRET_KEY
  }
});

exports.handler = async ({ scrapeUrl, timeout = 5000 }) => {
  try {
    const res = await axios(scrapeUrl, { method: "GET", timeout });

    if (res.data) {
      console.log("Data scraped successfully.");
      await saveData({ data: JSON.stringify(res.data) });
    }
  } catch (error) {
    console.error("Unable to scrape data.");
    throw error;
  }
}

/**
 * Save and handle the JSON dataset appropriately.
 * (S3 File or Database etc)
 */
const saveData = async ({ data }) => {
  try {
    const params = {
      Bucket: process.env.BUCKET_NAME,
      Key: "data.json",
      Body: data,
      ContentType: "application/json"
    };

    await s3Client.putObject(params).promise();
    console.log("Data uploaded successfully.");
  } catch (error) {
    console.error("Unable to upload data.");
    throw error;
  }
}