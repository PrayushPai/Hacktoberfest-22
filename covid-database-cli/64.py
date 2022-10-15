import subprocess as sp
import pymysql
import pymysql.cursors
from tabulate import tabulate


def viewTable(rows):

    a = []
    try:
        a.append(list(rows[0].keys()))
    except:
        print("\n-----------------\nEMPTY TABLE\n-----------------\n")
        return
    for row in rows:
        b = []
        for k in row.keys():
            b.append(row[k])
        a.append(b)
    print(tabulate(a, tablefmt="psql", headers="firstrow"))
    print()
    return


def listPeople():
    query = "SELECT * FROM Person;"
    try:
        no_of_rows = cur.execute(query)
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return

    rows = cur.fetchall()
    viewTable(rows)
    con.commit()
    # return


def listVolunteers():
    query = "SELECT * FROM Volunteer;"
    try:
        no_of_rows = cur.execute(query)
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return

    rows = cur.fetchall()
    viewTable(rows)
    con.commit()
    # return
    return


def listDependents():
    try:
        a = int(input("Enter volunteer ID: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    query = "SELECT Name FROM Dependents WHERE VID = %d;" % (a)
    try:
        no_of_rows = cur.execute(query)
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    rows = cur.fetchall()
    viewTable(rows)
    con.commit()
    # return
    return


def removeDependents():
    try:
        a = int(input("Enter volunteer ID:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    b = input("Enter dependent name: ")
    query = "DELETE FROM Dependents WHERE VID=%d AND Name='%s'" % (a, b)
    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    return


def removeVolunteer():
    try:
        a = int(input("Enter volunteer ID:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    # b = input("Enter dependent name: ")
    query = "DELETE FROM Volunteer WHERE Volunteer_ID=%d" % (a)
    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    return


def removePerson():
    try:
        a = int(input("Enter Aadhar no:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    # b = input("Enter dependent name: ")
    query = "DELETE FROM Person WHERE Aadhar_no=%d" % (a)
    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    return


def addDependent():
    brow = {}
    print("Enter dependent details: ")
    brow["name"] = input("Enter name: ")
    try:
        brow["vid"] = int(
            input("Enter volunteer ID to whom the dependent is related to:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    query = "INSERT INTO `Dependents` VALUES ('%s',%d);" % (
        brow["name"], brow["vid"])
    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    return


def addPerson():
    row = {}
    print("Enter person details: ")
    try:
        row["Aadhar"] = int(input("Enter Aadhar no:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    row["State_name"] = input("State name: ")
    row["Person_name"] = input("Name: ")
    row["dob"] = input("Date of birth in YYYY-MM-DD format: ")
    row["gender"] = input("Gender: ")
    try:
        row["HNo"] = int(input("House no: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    row["City"] = input("City: ")
    row["area"] = input("Area: ")
    try:
        row["pincode"] = int(input("Pin code: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    query = "INSERT INTO `Person` VALUES (%d, '%s','%s','%s','%s',%d,'%s','%s','%s',%d);" % (
        row["Aadhar"], row["State_name"], row["Person_name"], row["dob"], row["gender"], row["HNo"], row["City"], row["State_name"], row["area"], row["pincode"])
    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    return


def addVolunteer():
    arow = {}
    print("Enter volunteer details: ")
    try:
        arow["Volunteer_ID"] = int(input("Enter Volunteer ID:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    arow["State_name"] = input("State name: ")
    arow["Person_name"] = input("Name: ")
    arow["dob"] = input("Date of birth in YYYY-MM-DD format: ")
    arow["gender"] = input("Gender: ")
    try:
        arow["HNo"] = int(input("House no: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    arow["City"] = input("City: ")
    arow["area"] = input("Area: ")
    try:
        arow["pincode"] = int(input("Pin code: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    try:
        arow["aadhar"] = int(input("Enter Volunteer Aadhar no: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    try:
        arow["aware"] = int(
            input("Is the volunteer's job spreading awareness (enter 0 or 1): "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    try:
        arow["vaccinate"] = int(
            input("Is the volunteer's job vaccinating people (enter 0 or 1): "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    query = "INSERT INTO `Volunteer` VALUES (%d, '%s','%s','%s','%s',%d,'%s','%s','%s',%d, %d, %d, %d);" % (
        arow["Volunteer_ID"], arow["State_name"], arow["Person_name"], arow["dob"], arow["gender"], arow["HNo"], arow["City"], arow["State_name"], arow["area"], arow["pincode"], arow["aadhar"], arow["aware"], arow["vaccinate"])
    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    return


def updatePersonDetails():
    row = {}
    # print("Enter person details: ")
    try:
        row["Aadhar"] = int(
            input("Enter Aadhar no of the person you wish to update:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    print("Enter all the other details: ")
    row["State_name"] = input("State name: ")
    row["Person_name"] = input("Name: ")
    row["dob"] = input("Date of birth in YYYY-MM-DD format: ")
    row["gender"] = input("Gender: ")
    try:
        row["HNo"] = int(input("House no: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    row["City"] = input("City: ")
    row["area"] = input("Area: ")
    try:
        row["pincode"] = int(input("Pin code: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    query = "UPDATE `Person` SET Sname='%s',Name='%s',Date_of_birth='%s',Gender='%s',HNo=%d,City='%s',State='%s',Area='%s',Pin_code=%d WHERE Aadhar_no=%d;" % (
        row["State_name"], row["Person_name"], row["dob"], row["gender"], row["HNo"], row["City"], row["State_name"], row["area"], row["pincode"], row["Aadhar"])
    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    return


def updateVolunteerDetails():
    arow = {}
    # print("Enter volunteer details: ")
    try:
        arow["Volunteer_ID"] = int(
            input("Enter ID of the volunteer you wish to update:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    arow["State_name"] = input("State name: ")
    arow["Person_name"] = input("Name: ")
    arow["dob"] = input("Date of birth in YYYY-MM-DD format: ")
    arow["gender"] = input("Gender: ")
    try:
        arow["HNo"] = int(input("House no: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    arow["City"] = input("City: ")
    arow["area"] = input("Area: ")
    try:
        arow["pincode"] = int(input("Pin code: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    try:
        arow["aadhar"] = int(input("Enter Volunteer Aadhar no: "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    try:
        arow["aware"] = int(
            input("Is the volunteer's job spreading awareness (enter 0 or 1): "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    try:
        arow["vaccinate"] = int(
            input("Is the volunteer's job vaccinating people (enter 0 or 1): "))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    query = "UPDATE `Volunteer` SET Sname='%s',Volunteer_name='%s',Volunteer_date_of_birth='%s',Volunteer_gender='%s',Volunteer_HNo=%d,Volunteer_city='%s',Volunteer_state='%s',Volunteer_area='%s',Volunteer_pin_code=%d,Volunteer_aadhar_no=%d,Spread_flag=%d,Vaccinate_flag=%d WHERE Volunteer_ID=%d;" % (
        arow["State_name"], arow["Person_name"], arow["dob"], arow["gender"], arow["HNo"], arow["City"], arow["State_name"], arow["area"], arow["pincode"], arow["aadhar"], arow["aware"], arow["vaccinate"], arow["Volunteer_ID"])
    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    return


def updateVaccinationstatus():
    try:
        aadhar = int(input(
            "Enter Aadhar no of the person whose vaccination status you wish to update:"))
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return
    print("Enter the following details")
    status = input("Enter updated status (Full/Partial/None): ")
    datefirst = input("Enter date of first vaccination: ")
    datesecond = input("Enter date of second vaccination: ")
    if datefirst == "" and datesecond != "":
        query = "UPDATE `Vaccination_status` SET Status='%s', Date_of_first_vaccination=NULL, Date_of_second_vaccination='%s' WHERE Paadhar_no=%d;" % (
            status, datesecond, aadhar)
    elif datesecond == "" and datefirst != "":
        query = "UPDATE `Vaccination_status` SET Status='%s', Date_of_first_vaccination='%s', Date_of_second_vaccination=NULL WHERE Paadhar_no=%d;" % (
            status, datefirst, aadhar)
    elif datesecond == "" and datefirst == "":
        query = "UPDATE `Vaccination_status` SET Status='%s', Date_of_first_vaccination=NULL, Date_of_second_vaccination=NULL WHERE Paadhar_no=%d;" % (
            status, aadhar)
    else:
        query = "UPDATE `Vaccination_status` SET Status='%s', Date_of_first_vaccination='%s', Date_of_second_vaccination='%s' WHERE Paadhar_no=%d;" % (
            status, datefirst, datesecond, aadhar)

    try:
        cur.execute(query)
        con.commit()
    except Exception as e:
        print(e)
        print("\n\nError: PLEASE TRY AGAIN WITH DIFFERENT DATA!\n")
        return


def dispatch(ch):
    """
    Function that maps helper functions to option entered
    """

    if(ch == 1):
        listPeople()
    elif(ch == 2):
        listVolunteers()
    elif(ch == 3):
        listDependents()
    elif(ch == 4):
        removeDependents()
    elif(ch == 5):
        removeVolunteer()
    elif(ch == 6):
        removePerson()
    elif(ch == 7):
        addDependent()
    elif(ch == 8):
        addPerson()
    elif(ch == 9):
        addVolunteer()
    elif(ch == 10):
        updatePersonDetails()
    elif(ch == 11):
        updateVolunteerDetails()
    elif(ch == 12):
        updateVaccinationstatus()
    else:
        print("Error: Invalid Option")


while(1):
    tmp = sp.call('clear', shell=True)
    username = input("Username: ")
    password = input("Password: ")

    try:
        con = pymysql.connect(host='localhost',
                              port=3306,
                              user=username,
                              password=password,
                              db='Covid',
                              cursorclass=pymysql.cursors.DictCursor)
        tmp = sp.call('clear', shell=True)

        if(con.open):
            print("Connected")
        else:
            print("Failed to connect")

        tmp = input("Enter any key to CONTINUE>")

        with con.cursor() as cur:
            while(1):
                tmp = sp.call('clear', shell=True)
                print("1. List all the people details")
                print("2. List all the volunteers details")
                print("3. List all the dependents of a volunteer")
                print("4. Remove a dependent of volunteer")
                print("5. Remove a volunteer")
                print("6. Remove a person")
                print("7. Add a dependent of volunteer")
                print("8. Add a person")
                print("9. Add a volunteer")
                print("10. Update person details")
                print("11. Update volunteer details")
                print("12. Update vaccination status")
                print("13. Logout")
                ch = int(input("Enter choice> "))
                tmp = sp.call('clear', shell=True)
                if ch == 13:
                    exit()
                else:
                    dispatch(ch)
                    tmp = input("Enter any key to CONTINUE>")

    except Exception as e:
        tmp = sp.call('clear', shell=True)
        print(e)
        print("Connection Refused: Either username or password is incorrect or user doesn't have access to database")
        tmp = input("Enter any key to CONTINUE>")
