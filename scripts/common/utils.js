const { isHexString, addHexPrefix } = require("ethereumjs-util");

function validateMsgHash(msgHash) {
    const isHex = isHexString(msgHash) || isHexString(addHexPrefix(msgHash));

    if (!isHex && !(msgHash instanceof Uint8Array)) {
        throw new Error("MsgHash must be hex string or Uint8Array");
    }
}

function prepareForSerialization(obj) {
    if (obj instanceof Uint8Array) obj = Array.from(obj);

    const typeOfObj = typeof obj;

    if (typeOfObj === "bigint" || typeOfObj === "number") {
        return obj.toString();
    }

    if (Array.isArray(obj)) {
        return obj.map((element) => prepareForSerialization(element));
    }

    if (typeOfObj === "object" && obj !== null) {
        const result = {};
        for (const [key, value] of Object.entries(obj)) {
            result[key] = prepareForSerialization(value);
        }
        return result;
    }

    return obj;
}

module.exports = {
    validateMsgHash,
    prepareForSerialization,
};
