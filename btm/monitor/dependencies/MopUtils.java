package mop;

class MopUtils {

    static String stateToString(int state) {
        if (state == 2) {
            return "Prepared";
        } else if (state == 3) {
            return "Committed";
        } else if (state == 4) {
            return "Rolledback";
        } else if (state == 5) {
            return "Unknown";
        } else if (state == 6) {
            return "Init";
        } else if (state == 7) {
            return "Preparing";
        } else if (state == 8) {
            return "Committing";
        } else if (state == 9) {
            return "Rollingback";
        } else {
            return "Unknown";
        }
    }

}
